# Lock-In 1v1 Battle WebSocket Server

High-performance, lightweight Node.js WebSocket server powering the real-time 1v1 Focus Battle experience in Lock-In.

---

## ⚡ Features
- **Instant P2P Matchmaking**: In-memory room lookup with 6-character room codes.
- **Synchronized Authoritative Battles**: Millisecond-accurate countdown synchronization.
- **Heartbeat / Keep-Alive**: Automatic 30-second ping/pong cycles preventing mobile OS timeouts.
- **Render-Ready**: Native `/health` endpoint for zero-downtime free deployment on Render.

---

## 🚀 Running Locally (for Phone + PC / Emulator testing)

```bash
cd server
npm install
npm start
```

The server starts on port `8080`:
- Local: `ws://localhost:8080` (or `ws://10.0.2.2:8080` from Android Emulator)
- Wi-Fi: `ws://<YOUR_PC_LOCAL_IP>:8080` (e.g. `ws://192.168.1.5:8080`)
- Health check: `http://localhost:8080/health`

---

## 🌐 Deploying to Render (Free Cloud Hosting)

1. Push this repository to GitHub.
2. Log in to [Render.com](https://dashboard.render.com).
3. Click **New +** -> **Web Service**.
4. Connect your `Lock-In` repository.
5. Set:
   - **Root Directory**: `server`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: `Free`
6. Render gives you a public URL (e.g. `https://lockin-battle-server.onrender.com`).
7. In Flutter, your WebSocket endpoint is:
   ```dart
   wss://lockin-battle-server.onrender.com
   ```
