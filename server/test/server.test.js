const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert');
const { WebSocket } = require('ws');
const {
  server,
  wss,
  rooms,
  generateRoomCode,
  serializeBattle,
} = require('../server.js');

let serverUrl;
let wsUrl;

function createClient() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    const messages = [];
    const queue = [];

    ws.on('open', () => resolve({ ws, nextMessage, getAllMessages: () => messages }));
    ws.on('error', (err) => reject(err));

    ws.on('message', (raw) => {
      try {
        const data = JSON.parse(raw.toString());
        messages.push(data);
        if (queue.length > 0) {
          const { resolveMsg, filter } = queue.shift();
          if (!filter || filter(data)) {
            resolveMsg(data);
          } else {
            queue.unshift({ resolveMsg, filter });
          }
        }
      } catch (e) {
        messages.push(raw.toString());
      }
    });

    function nextMessage(filter, timeoutMs = 2500) {
      // Check already received messages first
      const idx = messages.findIndex((m) => (filter ? filter(m) : true));
      if (idx !== -1) {
        const [msg] = messages.splice(idx, 1);
        return Promise.resolve(msg);
      }

      return new Promise((res, rej) => {
        const timer = setTimeout(() => {
          rej(new Error(`Timeout waiting for message matching condition after ${timeoutMs}ms`));
        }, timeoutMs);

        queue.push({
          resolveMsg: (msg) => {
            clearTimeout(timer);
            const removeIdx = messages.indexOf(msg);
            if (removeIdx !== -1) messages.splice(removeIdx, 1);
            res(msg);
          },
          filter,
        });
      });
    }
  });
}

describe('Lock-In Battle Server Tests', () => {
  before(async () => {
    await new Promise((resolve) => {
      server.listen(0, '127.0.0.1', () => {
        const port = server.address().port;
        serverUrl = `http://127.0.0.1:${port}`;
        wsUrl = `ws://127.0.0.1:${port}`;
        resolve();
      });
    });
  });

  after(async () => {
    await new Promise((resolve) => {
      wss.close(() => {
        server.close(resolve);
      });
    });
  });

  beforeEach(() => {
    rooms.clear();
  });

  describe('Unit Functions', () => {
    test('generateRoomCode generates 6-character uppercase alphanumeric code', () => {
      for (let i = 0; i < 20; i++) {
        const code = generateRoomCode();
        assert.strictEqual(code.length, 6);
        assert.match(code, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/);
      }
    });

    test('serializeBattle formats room and participant state accurately', () => {
      const mockRoom = {
        battleId: 'test-battle-1',
        roomCode: 'TEST99',
        durationMinutes: 25,
        status: 'waitingForReady',
        host: {
          id: 'host-1',
          displayName: 'HostPlayer',
          avatar: 'avatar1.png',
          isReady: true,
          status: 'ready',
        },
        guest: {
          id: 'guest-1',
          displayName: 'GuestPlayer',
          avatar: 'avatar2.png',
          isReady: false,
          status: 'joined',
        },
        createdAt: '2026-08-31T00:00:00.000Z',
        startedAt: null,
      };

      const serialized = serializeBattle(mockRoom);
      assert.strictEqual(serialized.id, 'test-battle-1');
      assert.strictEqual(serialized.roomCode, 'TEST99');
      assert.strictEqual(serialized.durationMinutes, 25);
      assert.strictEqual(serialized.status, 'waitingForReady');
      assert.strictEqual(serialized.participants.length, 2);
      assert.strictEqual(serialized.participants[0].id, 'host-1');
      assert.strictEqual(serialized.participants[0].isHost, true);
      assert.strictEqual(serialized.participants[0].isReady, true);
      assert.strictEqual(serialized.participants[1].id, 'guest-1');
      assert.strictEqual(serialized.participants[1].isHost, false);
      assert.strictEqual(serialized.participants[1].isReady, false);
    });
  });

  describe('HTTP Endpoints', () => {
    test('GET /health returns status ok, active rooms, and uptime', async () => {
      const res = await fetch(`${serverUrl}/health`);
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.headers.get('content-type'), 'application/json');

      const data = await res.json();
      assert.strictEqual(data.status, 'ok');
      assert.strictEqual(typeof data.activeRooms, 'number');
      assert.strictEqual(typeof data.uptimeSeconds, 'number');
    });

    test('GET /healthz returns status ok', async () => {
      const res = await fetch(`${serverUrl}/healthz`);
      assert.strictEqual(res.status, 200);

      const data = await res.json();
      assert.strictEqual(data.status, 'ok');
    });

    test('GET / returns battle server information', async () => {
      const res = await fetch(`${serverUrl}/`);
      assert.strictEqual(res.status, 200);

      const data = await res.json();
      assert.strictEqual(data.name, 'Lock-In 1v1 Battle Server');
      assert.strictEqual(data.status, 'running');
      assert.strictEqual(data.activeRooms, 0);
    });
  });

  describe('WebSocket Lifecycle & Communication', () => {
    test('Host creates a room and receives ROOM_CREATED', async () => {
      const host = await createClient();
      try {
        host.ws.send(
          JSON.stringify({
            type: 'CREATE_ROOM',
            displayName: 'Alice',
            durationMinutes: 25,
            avatar: 'assets/pfp1.svg',
          }),
        );

        const msg = await host.nextMessage((m) => m.type === 'ROOM_CREATED');
        assert.strictEqual(msg.type, 'ROOM_CREATED');
        assert.strictEqual(msg.roomCode.length, 6);
        assert.ok(msg.battleId);
        assert.ok(msg.participantId);
        assert.ok(msg.participantToken);
        assert.strictEqual(msg.battle.participants.length, 1);
        assert.strictEqual(msg.battle.participants[0].displayName, 'Alice');
        assert.strictEqual(rooms.has(msg.roomCode), true);
      } finally {
        host.ws.close();
      }
    });

    test('Joining a non-existent room returns ROOM_NOT_FOUND error', async () => {
      const guest = await createClient();
      try {
        guest.ws.send(
          JSON.stringify({
            type: 'JOIN_ROOM',
            roomCode: 'NONO99',
            displayName: 'Bob',
          }),
        );

        const err = await guest.nextMessage((m) => m.type === 'ERROR');
        assert.strictEqual(err.type, 'ERROR');
        assert.strictEqual(err.code, 'ROOM_NOT_FOUND');
      } finally {
        guest.ws.close();
      }
    });

    test('Guest joins an existing room: Guest gets ROOM_JOINED, Host gets PLAYER_JOINED', async () => {
      const host = await createClient();
      const guest = await createClient();

      try {
        host.ws.send(
          JSON.stringify({
            type: 'CREATE_ROOM',
            displayName: 'Alice',
            durationMinutes: 30,
          }),
        );

        const createdMsg = await host.nextMessage((m) => m.type === 'ROOM_CREATED');
        const roomCode = createdMsg.roomCode;

        guest.ws.send(
          JSON.stringify({
            type: 'JOIN_ROOM',
            roomCode,
            displayName: 'Bob',
          }),
        );

        const guestJoinedMsg = await guest.nextMessage((m) => m.type === 'ROOM_JOINED');
        assert.strictEqual(guestJoinedMsg.type, 'ROOM_JOINED');
        assert.strictEqual(guestJoinedMsg.roomCode, roomCode);
        assert.strictEqual(guestJoinedMsg.battle.participants.length, 2);

        const hostPlayerJoinedMsg = await host.nextMessage((m) => m.type === 'PLAYER_JOINED');
        assert.strictEqual(hostPlayerJoinedMsg.type, 'PLAYER_JOINED');
        assert.strictEqual(hostPlayerJoinedMsg.participant.displayName, 'Bob');
      } finally {
        host.ws.close();
        guest.ws.close();
      }
    });

    test('Reject third participant when room is already full', async () => {
      const host = await createClient();
      const guest1 = await createClient();
      const guest2 = await createClient();

      try {
        host.ws.send(JSON.stringify({ type: 'CREATE_ROOM', displayName: 'Host' }));
        const created = await host.nextMessage((m) => m.type === 'ROOM_CREATED');

        guest1.ws.send(JSON.stringify({ type: 'JOIN_ROOM', roomCode: created.roomCode, displayName: 'Guest 1' }));
        await guest1.nextMessage((m) => m.type === 'ROOM_JOINED');

        // Third player tries to join
        guest2.ws.send(JSON.stringify({ type: 'JOIN_ROOM', roomCode: created.roomCode, displayName: 'Guest 2' }));
        const err = await guest2.nextMessage((m) => m.type === 'ERROR');
        assert.strictEqual(err.type, 'ERROR');
        assert.strictEqual(err.code, 'ROOM_FULL');
      } finally {
        host.ws.close();
        guest1.ws.close();
        guest2.ws.close();
      }
    });

    test('Ready toggles, Start battle, and Progress updates sync between peers', async () => {
      const host = await createClient();
      const guest = await createClient();

      try {
        host.ws.send(JSON.stringify({ type: 'CREATE_ROOM', displayName: 'Host', durationMinutes: 20 }));
        const created = await host.nextMessage((m) => m.type === 'ROOM_CREATED');

        guest.ws.send(JSON.stringify({ type: 'JOIN_ROOM', roomCode: created.roomCode, displayName: 'Guest' }));
        const guestJoined = await guest.nextMessage((m) => m.type === 'ROOM_JOINED');
        await host.nextMessage((m) => m.type === 'PLAYER_JOINED');

        // Guest sets ready
        guest.ws.send(JSON.stringify({ type: 'PLAYER_READY', participantId: guestJoined.participantId }));
        const hostGotReady = await host.nextMessage((m) => m.type === 'PLAYER_READY');
        assert.strictEqual(hostGotReady.participantId, guestJoined.participantId);

        // Guest sets unready
        guest.ws.send(JSON.stringify({ type: 'PLAYER_UNREADY', participantId: guestJoined.participantId }));
        const hostGotUnready = await host.nextMessage((m) => m.type === 'PLAYER_UNREADY');
        assert.strictEqual(hostGotUnready.participantId, guestJoined.participantId);

        // Start battle
        host.ws.send(JSON.stringify({ type: 'START_BATTLE' }));
        const hostStart = await host.nextMessage((m) => m.type === 'BATTLE_STARTED');
        const guestStart = await guest.nextMessage((m) => m.type === 'BATTLE_STARTED');
        assert.strictEqual(hostStart.type, 'BATTLE_STARTED');
        assert.strictEqual(guestStart.type, 'BATTLE_STARTED');
        assert.strictEqual(hostStart.durationSeconds, 20 * 60);

        // Progress update from Host to Guest
        host.ws.send(
          JSON.stringify({
            type: 'PROGRESS_UPDATE',
            participantId: created.participantId,
            elapsedSeconds: 60,
            remainingSeconds: 1140,
            progressPercent: 0.05,
          }),
        );
        const guestProgress = await guest.nextMessage((m) => m.type === 'PROGRESS_UPDATE');
        assert.strictEqual(guestProgress.elapsedSeconds, 60);
        assert.strictEqual(guestProgress.remainingSeconds, 1140);
      } finally {
        host.ws.close();
        guest.ws.close();
      }
    });

    test('Finish and Forfeit battle events relay to opponent', async () => {
      const host = await createClient();
      const guest = await createClient();

      try {
        host.ws.send(JSON.stringify({ type: 'CREATE_ROOM', displayName: 'Host' }));
        const created = await host.nextMessage((m) => m.type === 'ROOM_CREATED');

        guest.ws.send(JSON.stringify({ type: 'JOIN_ROOM', roomCode: created.roomCode, displayName: 'Guest' }));
        const guestJoined = await guest.nextMessage((m) => m.type === 'ROOM_JOINED');
        await host.nextMessage((m) => m.type === 'PLAYER_JOINED');

        // Finish
        host.ws.send(JSON.stringify({ type: 'PLAYER_FINISH', participantId: created.participantId }));
        const guestFinish = await guest.nextMessage((m) => m.type === 'PLAYER_FINISHED');
        assert.strictEqual(guestFinish.participantId, created.participantId);

        // Forfeit
        guest.ws.send(JSON.stringify({ type: 'PLAYER_FORFEIT', participantId: guestJoined.participantId }));
        const hostForfeit = await host.nextMessage((m) => m.type === 'PLAYER_FORFEITED');
        assert.strictEqual(hostForfeit.participantId, guestJoined.participantId);
      } finally {
        host.ws.close();
        guest.ws.close();
      }
    });

    test('Host disconnection cancels battle and removes room', async () => {
      const host = await createClient();
      const guest = await createClient();

      try {
        host.ws.send(JSON.stringify({ type: 'CREATE_ROOM', displayName: 'Host' }));
        const created = await host.nextMessage((m) => m.type === 'ROOM_CREATED');

        guest.ws.send(JSON.stringify({ type: 'JOIN_ROOM', roomCode: created.roomCode, displayName: 'Guest' }));
        await guest.nextMessage((m) => m.type === 'ROOM_JOINED');
        await host.nextMessage((m) => m.type === 'PLAYER_JOINED');

        // Host closes socket
        host.ws.close();

        const guestCancelled = await guest.nextMessage((m) => m.type === 'BATTLE_CANCELLED');
        assert.strictEqual(guestCancelled.type, 'BATTLE_CANCELLED');
        assert.strictEqual(rooms.has(created.roomCode), false);
      } finally {
        guest.ws.close();
      }
    });

    test('Sending invalid JSON yields ERROR message without crashing', async () => {
      const client = await createClient();
      try {
        client.ws.send('invalid-json-payload{{{');
        const err = await client.nextMessage((m) => m.type === 'ERROR');
        assert.strictEqual(err.type, 'ERROR');
        assert.strictEqual(err.message, 'Invalid JSON payload');
      } finally {
        client.ws.close();
      }
    });
  });
});
