# LockIn — Focus Battle Backend & WebSocket Contract

## 1. Overview & Philosophy

LockIn Focus Battles support **Guest Multiplayer**:
Two users can initiate, join, synchronize, and complete a live 1-on-1 focus duel **without creating an account**.

The core architectural flow:
```text
User A (Host)                      Backend                      User B (Guest)
     │                                │                               │
     │── POST /api/v1/battles ───────>│                               │
     │<── battleId, K7XM4P, tokenA ───│                               │
     │                                │                               │
     │── [Share Code "K7XM4P"] ──────────────────────────────────────>│
     │                                │                               │
     │                                │<── POST /api/v1/battles/join ─│
     │                                │─── battleId, tokenB ─────────>│
     │                                │                               │
     │── WebSocket Connect (tokenA) ─>│<── WebSocket Connect (tokenB)─│
     │                                │                               │
     │<─────────────── Realtime Events (READY, START) ───────────────>│
     │                                │                               │
     │    [Both focus simultaneously; countdown derived from server]  │
     │                                │                               │
     │<────────────── State Transitions / Forfeit / Result ──────────>│
```

---

## 2. Authentication & Identity Model

### 2.1 Anonymous Device Identity
- Generated locally on client installation: `anonymousId = UUIDv4`
- Persisted in client's local storage.
- Sent in REST payloads to correlate temporary sessions.
- **Never contains PII or hardware serials.**

### 2.2 Battle Participant Token
- When a room is created or joined, the server issues a scoped `participantToken` (e.g., HMAC-signed JWT or secure random bearer token).
- Tokens are scoped strictly to:
  - `battleId`
  - `participantId`
  - Lifetime of the battle + grace period (e.g., 2 hours).

---

## 3. REST API Specification

Base URL: `/api/v1`

### 3.1 Create Battle Room
`POST /api/v1/battles`

**Request Headers:**
```http
Content-Type: application/json
```

**Request Body:**
```json
{
  "durationMinutes": 25,
  "displayName": "Abhay",
  "anonymousId": "550e8400-e29b-41d4-a716-446655440000",
  "avatar": "assets/default_pfp/avatar-spark.svg"
}
```

**Response (201 Created):**
```json
{
  "battleId": "d3b07384-d113-4f9e-a892-0b1a2386927a",
  "roomCode": "K7XM4P",
  "participantId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "participantToken": "eyJhbGciOi...",
  "battle": {
    "id": "d3b07384-d113-4f9e-a892-0b1a2386927a",
    "roomCode": "K7XM4P",
    "durationMinutes": 25,
    "status": "waitingForPlayer",
    "participants": [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "displayName": "Abhay",
        "avatar": "assets/default_pfp/avatar-spark.svg",
        "status": "joined",
        "focusedSeconds": 0,
        "isHost": true
      }
    ],
    "createdAt": "2026-08-26T10:00:00.000Z",
    "gracePeriodSeconds": 30
  }
}
```

---

### 3.2 Join Battle Room
`POST /api/v1/battles/join`

**Request Body:**
```json
{
  "roomCode": "K7XM4P",
  "displayName": "Rahul",
  "anonymousId": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  "avatar": "assets/default_pfp/avatar-sun.svg"
}
```

**Response (200 OK):**
```json
{
  "battleId": "d3b07384-d113-4f9e-a892-0b1a2386927a",
  "participantId": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
  "participantToken": "eyJhbGciOi...",
  "battle": {
    "id": "d3b07384-d113-4f9e-a892-0b1a2386927a",
    "roomCode": "K7XM4P",
    "durationMinutes": 25,
    "status": "waitingForReady",
    "participants": [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "displayName": "Abhay",
        "status": "joined",
        "isHost": true
      },
      {
        "id": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
        "displayName": "Rahul",
        "status": "joined",
        "isHost": false
      }
    ],
    "createdAt": "2026-08-26T10:00:00.000Z"
  }
}
```

**Error Responses:**
- `404 Not Found`: `{ "error": "BATTLE_NOT_FOUND", "message": "Room code K7XM4P does not exist or has expired." }`
- `409 Conflict`: `{ "error": "BATTLE_FULL", "message": "Room already has 2 participants." }`
- `410 Gone`: `{ "error": "BATTLE_EXPIRED", "message": "Room has expired." }`

---

## 4. WebSocket Protocol

**Endpoint:** `GET /ws/battles/{battleId}?token={participantToken}`

### 4.1 Server Authoritative Clock (Critical)
The WebSocket **never** broadcasts tick-by-tick (59:59, 59:58...).
When both participants are ready, the server starts the battle and emits `BATTLE_STARTED`:
```json
{
  "event": "BATTLE_STARTED",
  "battleId": "d3b07384-d113-4f9e-a892-0b1a2386927a",
  "timestamp": "2026-08-26T10:05:00.000Z",
  "payload": {
    "startedAt": "2026-08-26T10:05:00.000Z",
    "durationSeconds": 1500
  }
}
```
Clients independently calculate:
$$\text{remaining} = (\text{startedAt} + \text{durationSeconds}) - \text{currentTimestamp}$$

---

### 4.2 Event Message Schema

#### Player Ready
**Client → Server / Server → Client:**
```json
{
  "event": "PLAYER_READY",
  "battleId": "d3b07384-d113-4f9e-a892-0b1a2386927a",
  "timestamp": "2026-08-26T10:04:50.000Z",
  "payload": {
    "participantId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  }
}
```

#### Player Forfeited (Lock-In Mode violation or Concede)
**Client → Server / Server → Client:**
```json
{
  "event": "PLAYER_FORFEITED",
  "battleId": "d3b07384-d113-4f9e-a892-0b1a2386927a",
  "timestamp": "2026-08-26T10:18:22.000Z",
  "payload": {
    "participantId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "reason": "Left the application"
  }
}
```

#### Disconnect vs Forfeit Grace Period
When a WebSocket TCP disconnects without a forfeit event:
1. Server marks participant as `DISCONNECTED`.
2. Emits `PLAYER_DISCONNECTED` with a grace countdown (default 30 seconds).
3. If player reconnects with same `participantToken` before expiry: emits `PLAYER_RECONNECTED`.
4. If grace period expires without reconnection: Server converts status to `FORFEITED` and completes battle.

#### Battle Finished
**Server → Clients:**
```json
{
  "event": "BATTLE_FINISHED",
  "battleId": "d3b07384-d113-4f9e-a892-0b1a2386927a",
  "timestamp": "2026-08-26T10:30:00.000Z",
  "payload": {
    "winnerId": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
    "isDraw": false,
    "completedAt": "2026-08-26T10:30:00.000Z"
  }
}
```

#### Battle Overtime / Session Extension
When a duel concludes and participants wish to sustain their flow state, the room Host can trigger an overtime extension directly from the match result screen:

**Host → Server (`EXTEND_BATTLE`):**
```json
{
  "type": "EXTEND_BATTLE",
  "participantId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "extensionMinutes": 10
}
```

**Server → Clients (`BATTLE_EXTENDED`):**
```json
{
  "type": "BATTLE_EXTENDED",
  "extensionMinutes": 10,
  "extensionSeconds": 600,
  "startedAt": "2026-08-26T10:30:05.000Z"
}
```

Upon receiving `BATTLE_EXTENDED`, both host and guest clients:
1. Set the duel state back to `active`.
2. Accumulate previous focused minutes into base completed stats.
3. Automatically transition back to `BattleFocusScreen` with the overtime countdown.

---

## 5. Room Expiration & Cleanup
1. **Unstarted rooms:** Auto-expire 30 minutes after creation if no duel begins.
2. **Completed rooms:** Persist for 24 hours for audit/retrieval before deletion.
3. **Abandoned rooms:** Disconnect after 15 minutes of zero active sockets.
