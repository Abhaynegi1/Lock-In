const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');
const crypto = require('crypto');

const PORT = process.env.PORT || 8080;

// In-memory room storage: Map<roomCode, Room>
const rooms = new Map();

// Map each WebSocket connection to its current room & participant ID
const connectionMeta = new WeakMap();

function generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

function serializeBattle(room) {
  const participants = [];
  if (room.host) {
    participants.push({
      id: room.host.id,
      displayName: room.host.displayName,
      avatar: room.host.avatar,
      isHost: true,
      isReady: room.host.isReady,
      status: room.host.status || 'joined',
    });
  }
  if (room.guest) {
    participants.push({
      id: room.guest.id,
      displayName: room.guest.displayName,
      avatar: room.guest.avatar,
      isHost: false,
      isReady: room.guest.isReady,
      status: room.guest.status || 'joined',
    });
  }

  return {
    id: room.battleId,
    roomCode: room.roomCode,
    durationMinutes: room.durationMinutes,
    status: room.status,
    participants: participants,
    createdAt: room.createdAt,
    startedAt: room.startedAt || null,
  };
}

function sendJson(ws, data) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

// HTTP Server for Render health check & web endpoint
const server = http.createServer((req, res) => {
  if (req.url === '/health' || req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      activeRooms: rooms.size,
      uptimeSeconds: Math.floor(process.uptime()),
    }));
    return;
  }

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    name: 'Lock-In 1v1 Battle Server',
    status: 'running',
    activeRooms: rooms.size,
  }));
});

// WebSocket Server attached to HTTP server
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  connectionMeta.set(ws, { isAlive: true });

  ws.on('pong', () => {
    const meta = connectionMeta.get(ws);
    if (meta) meta.isAlive = true;
  });

  ws.on('message', (rawMessage) => {
    try {
      const data = JSON.parse(rawMessage.toString());
      handleMessage(ws, data);
    } catch (e) {
      console.error('[Server] Failed to parse message:', e.message);
      sendJson(ws, { type: 'ERROR', message: 'Invalid JSON payload' });
    }
  });

  ws.on('close', () => {
    handleDisconnect(ws);
  });

  ws.on('error', (err) => {
    console.error('[Server] WebSocket error:', err.message);
  });
});

function handleMessage(ws, msg) {
  const type = msg.type || msg.event;
  console.log(`[Server] Received message: ${type}`);

  switch (type) {
    case 'CREATE_ROOM': {
      let roomCode = generateRoomCode();
      while (rooms.has(roomCode)) {
        roomCode = generateRoomCode();
      }

      const battleId = crypto.randomUUID();
      const participantId = crypto.randomUUID();
      const participantToken = `token_${crypto.randomUUID()}`;

      const host = {
        id: participantId,
        displayName: msg.displayName || 'Host',
        avatar: msg.avatar || 'assets/default_pfp/avatar-spark.svg',
        isHost: true,
        isReady: false,
        status: 'joined',
        ws,
      };

      const room = {
        roomCode,
        battleId,
        durationMinutes: msg.durationMinutes || 25,
        status: 'waitingForPlayer',
        host,
        guest: null,
        createdAt: new Date().toISOString(),
        startedAt: null,
      };

      rooms.set(roomCode, room);
      connectionMeta.set(ws, { roomCode, participantId, isAlive: true });

      console.log(`[Server] Room ${roomCode} created by ${host.displayName}`);

      sendJson(ws, {
        type: 'ROOM_CREATED',
        roomCode,
        battleId,
        participantId,
        participantToken,
        battle: serializeBattle(room),
      });
      break;
    }

    case 'JOIN_ROOM': {
      const code = (msg.roomCode || '').trim().toUpperCase();
      const room = rooms.get(code);

      if (!room) {
        console.log(`[Server] Join failed: room ${code} not found`);
        sendJson(ws, {
          type: 'ERROR',
          code: 'ROOM_NOT_FOUND',
          message: `Room "${code}" does not exist or host is offline. Please verify the code.`,
        });
        return;
      }

      if (room.guest !== null && room.status !== 'waitingForPlayer') {
        sendJson(ws, {
          type: 'ERROR',
          code: 'ROOM_FULL',
          message: `Room "${code}" is already full.`,
        });
        return;
      }

      const participantId = crypto.randomUUID();
      const participantToken = `token_${crypto.randomUUID()}`;

      const guest = {
        id: participantId,
        displayName: msg.displayName || 'Guest',
        avatar: msg.avatar || 'assets/default_pfp/avatar-spark.svg',
        isHost: false,
        isReady: false,
        status: 'joined',
        ws,
      };

      room.guest = guest;
      room.status = 'waitingForReady';
      connectionMeta.set(ws, { roomCode: code, participantId, isAlive: true });

      console.log(`[Server] Guest ${guest.displayName} joined room ${code}`);

      // Respond to joining guest with full room data
      sendJson(ws, {
        type: 'ROOM_JOINED',
        roomCode: code,
        battleId: room.battleId,
        participantId,
        participantToken,
        battle: serializeBattle(room),
      });

      // Notify host that player joined
      sendJson(room.host.ws, {
        type: 'PLAYER_JOINED',
        participant: {
          id: guest.id,
          displayName: guest.displayName,
          avatar: guest.avatar,
          isHost: false,
          status: 'joined',
        },
        battle: serializeBattle(room),
      });
      break;
    }

    case 'PLAYER_READY': {
      const meta = connectionMeta.get(ws);
      if (!meta || !meta.roomCode) return;
      const room = rooms.get(meta.roomCode);
      if (!room) return;

      const pId = msg.participantId || meta.participantId;
      if (room.host && room.host.id === pId) room.host.isReady = true;
      if (room.guest && room.guest.id === pId) room.guest.isReady = true;

      // Broadcast to opponent
      const opponent = (room.host && room.host.id === pId) ? room.guest : room.host;
      if (opponent) {
        sendJson(opponent.ws, {
          type: 'PLAYER_READY',
          participantId: pId,
        });
      }
      break;
    }

    case 'PLAYER_UNREADY': {
      const meta = connectionMeta.get(ws);
      if (!meta || !meta.roomCode) return;
      const room = rooms.get(meta.roomCode);
      if (!room) return;

      const pId = msg.participantId || meta.participantId;
      if (room.host && room.host.id === pId) room.host.isReady = false;
      if (room.guest && room.guest.id === pId) room.guest.isReady = false;

      const opponent = (room.host && room.host.id === pId) ? room.guest : room.host;
      if (opponent) {
        sendJson(opponent.ws, {
          type: 'PLAYER_UNREADY',
          participantId: pId,
        });
      }
      break;
    }

    case 'START_BATTLE': {
      const meta = connectionMeta.get(ws);
      if (!meta || !meta.roomCode) return;
      const room = rooms.get(meta.roomCode);
      if (!room) return;

      room.status = 'active';
      const now = new Date().toISOString();
      room.startedAt = now;
      const durationSeconds = room.durationMinutes * 60;

      console.log(`[Server] Battle started in room ${room.roomCode}`);

      // Broadcast synchronized start to both clients
      const startPayload = {
        type: 'BATTLE_STARTED',
        startedAt: now,
        durationSeconds,
      };

      sendJson(room.host.ws, startPayload);
      if (room.guest) {
        sendJson(room.guest.ws, startPayload);
      }
      break;
    }

    case 'PROGRESS_UPDATE': {
      const meta = connectionMeta.get(ws);
      if (!meta || !meta.roomCode) return;
      const room = rooms.get(meta.roomCode);
      if (!room) return;

      const pId = msg.participantId || meta.participantId;
      const opponent = (room.host && room.host.id === pId) ? room.guest : room.host;
      if (opponent) {
        sendJson(opponent.ws, {
          type: 'PROGRESS_UPDATE',
          ...msg,
        });
      }
      break;
    }

    case 'PLAYER_FORFEIT': {
      const meta = connectionMeta.get(ws);
      if (!meta || !meta.roomCode) return;
      const room = rooms.get(meta.roomCode);
      if (!room) return;

      const pId = msg.participantId || meta.participantId;
      room.status = 'completed';

      const opponent = (room.host && room.host.id === pId) ? room.guest : room.host;
      if (opponent) {
        sendJson(opponent.ws, {
          type: 'PLAYER_FORFEITED',
          participantId: pId,
        });
      }
      break;
    }

    case 'PLAYER_FINISH': {
      const meta = connectionMeta.get(ws);
      if (!meta || !meta.roomCode) return;
      const room = rooms.get(meta.roomCode);
      if (!room) return;

      const pId = msg.participantId || meta.participantId;
      const opponent = (room.host && room.host.id === pId) ? room.guest : room.host;
      if (opponent) {
        sendJson(opponent.ws, {
          type: 'PLAYER_FINISHED',
          participantId: pId,
        });
      }
      break;
    }

    case 'LEAVE_ROOM': {
      handleDisconnect(ws);
      break;
    }

    default:
      console.log(`[Server] Unhandled message type: ${type}`);
  }
}

function handleDisconnect(ws) {
  const meta = connectionMeta.get(ws);
  if (!meta || !meta.roomCode) return;

  const roomCode = meta.roomCode;
  const pId = meta.participantId;
  const room = rooms.get(roomCode);

  if (!room) return;

  const isHost = room.host && room.host.id === pId;
  console.log(`[Server] Participant ${pId} (${isHost ? 'Host' : 'Guest'}) disconnected from room ${roomCode}`);

  if (isHost) {
    // If host leaves, cancel the battle for guest and delete room
    if (room.guest) {
      sendJson(room.guest.ws, {
        type: 'BATTLE_CANCELLED',
        message: 'The host has left or cancelled the battle room.',
      });
    }
    rooms.delete(roomCode);
  } else {
    // If guest leaves, notify host and reset room to waiting
    if (room.status === 'active') {
      sendJson(room.host.ws, {
        type: 'PLAYER_FORFEITED',
        participantId: pId,
      });
    } else {
      room.guest = null;
      room.status = 'waitingForPlayer';
      sendJson(room.host.ws, {
        type: 'PLAYER_LEFT',
        participantId: pId,
      });
    }
  }
  meta.roomCode = null;
}

// 30s Keep-Alive Heartbeat
const interval = setInterval(() => {
  wss.clients.forEach((ws) => {
    const meta = connectionMeta.get(ws);
    if (!meta || !meta.isAlive) {
      ws.terminate();
      return;
    }
    meta.isAlive = false;
    ws.ping();
  });
}, 30000);

// Allow test runners and background processes to exit cleanly
if (interval.unref) {
  interval.unref();
}

wss.on('close', () => {
  clearInterval(interval);
});

if (require.main === module) {
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`========================================`);
    console.log(` Lock-In Battle Server running on port ${PORT}`);
    console.log(` Health check: http://localhost:${PORT}/health`);
    console.log(` WebSocket URL: ws://localhost:${PORT}`);
    console.log(`========================================`);
  });
}

module.exports = {
  server,
  wss,
  rooms,
  connectionMeta,
  interval,
  generateRoomCode,
  serializeBattle,
  handleMessage,
  handleDisconnect,
};
