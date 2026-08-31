# 🐳 Docker Developer & Deployment Guide

Welcome to the **Lock-In** Docker guide. This project is fully containerized so any developer on Windows, macOS, or Linux can clone the repository, run a single command, and have the complete multi-tier system running with zero local SDK installations.

---

## 🏛️ Architecture Overview

```
                      [ Host Browser ]
                       │             │
        HTTP :3000     │             │    WebSocket :8080
       (App Interface) │             │    (Focus Battles)
                       ▼             ▼
          ┌───────────────────┐   ┌────────────────────────┐
          │  lockin-web-app   │   │  lockin-battle-server  │
          │   (Nginx Alpine)  │   │   (Node.js 20 Alpine)  │
          │                   │   │                        │
          │  • Compiled Wasm  │   │  • WebSocket Server    │
          │  • Gzip Engine    │   │  • /health Endpoint    │
          │  • SPA Fallback   │   │  • 1v1 Room Engine     │
          └───────────────────┘   └────────────────────────┘
                       ▲                     ▲
                       └──────────┬──────────┘
                                  │
                          [ lockin-net ]
                        (Bridge Network)
```

---

## 🚀 Quickstart (1 Command)

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/) (v2.0+)

### Launching the Full Stack
Run the following command from the root directory:

```bash
docker compose up --build
```

### Access Points
- **Flutter Web App**: Open [http://localhost:3000](http://localhost:3000)
- **Battle Server WebSocket**: `ws://localhost:8080`
- **Battle Server Health Check**: [http://localhost:8080/health](http://localhost:8080/health)

To run in detached background mode:
```bash
docker compose up --build -d
```

To stop all running services:
```bash
docker compose down
```

---

## ⚙️ Environment Variables & Customization

Docker Compose works out of the box with sensible defaults. To customize ports or external endpoints, copy `.env.example` to `.env` and modify as needed:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `WEB_PORT` | `3000` | Local port for the Flutter Web frontend |
| `BATTLE_SERVER_PORT` | `8080` | Local port for the WebSocket server |
| `BATTLE_SERVER_URL` | `ws://localhost:8080` | Client WebSocket connection string |
| `SUPABASE_URL` | *(Demo project)* | Supabase Auth & Cloud Backup URL |
| `SUPABASE_ANON_KEY` | *(Demo key)* | Supabase anonymous public API key |

To connect the web app to a remote battle server (such as Render):
```bash
BATTLE_SERVER_URL=wss://lock-in-websocket.onrender.com docker compose up --build
```

---

## 🧪 Running Automated Tests in Docker

You do not need Node.js or Flutter installed on your host machine to run quality checks and test suites.

### 1. Run Battle Server Tests
```bash
docker compose run --rm battle-server npm test
```

### 2. Run Flutter Analysis & Unit Tests
```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace ghcr.io/cirruslabs/flutter:stable bash -c "flutter pub get && flutter analyze && flutter test"
```

---

## 💻 Visual Studio Code & Codespaces DevContainer

For active development without installing local toolchains:

1. Install the **Dev Containers** extension in VS Code (`ms-vscode-remote.remote-containers`).
2. Open the `Lock-In` project folder in VS Code.
3. Click the bottom-left green button or press `Ctrl+Shift+P` / `Cmd+Shift+P`.
4. Select **Dev Containers: Reopen in Container**.
5. VS Code will build a dedicated container preloaded with:
   - Flutter SDK (stable channel)
   - Dart 3+
   - Node.js 20 & npm
   - Flutter & Dart VS Code extensions

---

## 🚢 Exporting & Deploying Containers

### 1. WebSocket Battle Server
The battle server is located in `./server` and can be deployed anywhere container workloads are supported:

**Build and Tag Image:**
```bash
docker build -t lockin-battle-server:latest ./server
```

**Deploy to Cloud Services:**
- **Render**: Connect repository, set Root Directory to `server`, choose Docker environment.
- **Google Cloud Run**:
  ```bash
  gcloud builds submit --tag gcr.io/[PROJECT_ID]/lockin-battle-server ./server
  gcloud run deploy lockin-battle-server --image gcr.io/[PROJECT_ID]/lockin-battle-server --port 8080
  ```
- **Fly.io / AWS ECS / Railway**: Use `server/Dockerfile` directly.

### 2. Flutter Web Production App
The frontend is compiled to a static bundle served by an ultra-lightweight Nginx Alpine container:

**Build with Custom Server URL:**
```bash
docker build \
  --build-arg BATTLE_SERVER_URL=wss://your-battle-server.onrender.com \
  -t lockin-web-app:latest .
```

**Run Standalone:**
```bash
docker run -d -p 80:80 lockin-web-app:latest
```

---

## 🛠️ Docker Cheatsheet

| Task | Command |
| :--- | :--- |
| **Start with rebuild** | `docker compose --env-file .env.docker up --build` |
| **Start detached** | `docker compose --env-file .env.docker up -d` |
| **View logs** | `docker compose logs -f` |
| **View server logs only** | `docker compose logs -f battle-server` |
| **Restart services** | `docker compose restart` |
| **Stop and remove containers** | `docker compose down` |
| **Remove containers and volumes** | `docker compose down -v` |
| **Inspect health status** | `docker compose ps` |
