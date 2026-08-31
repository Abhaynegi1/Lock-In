# ==============================================================================
# Lock-In Production Web Dockerfile
# Multi-stage build: Flutter Web compilation -> Nginx Alpine runtime
# ==============================================================================

# --- Stage 1: Build Flutter Web Bundle ---
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Enable web support
RUN flutter config --enable-web

# Cache pub dependencies layer
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full application source
COPY . .

# Build Arguments (can be overridden via docker build --build-arg or docker-compose)
ARG BATTLE_SERVER_URL=ws://localhost:8080
ARG SUPABASE_URL=https://xnnoastptbfeleguojzr.supabase.co
ARG SUPABASE_ANON_KEY=sb_publishable_eLVXDDrtl2z9kH5duJFIpQ_-pQvaoES

# Build production web bundle with tree-shaking and injected environment configurations
RUN flutter build web --release \
  --dart-define=BATTLE_SERVER_URL=${BATTLE_SERVER_URL} \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# --- Stage 2: Production Nginx Server ---
FROM nginx:alpine AS runner

# Copy compiled web output to Nginx document root
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration with SPA routing & compression
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose HTTP port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/index.html || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
