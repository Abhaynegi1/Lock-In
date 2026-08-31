# ==============================================================================
# Lock-In WebSocket Battle Server Dockerfile
# Lightweight, secure Node.js 20 Alpine runtime
# ==============================================================================

FROM node:20-alpine AS base

# Install curl for container health checks
RUN apk add --no-cache curl

WORKDIR /app

# Production environment configuration
ENV NODE_ENV=production
ENV PORT=8080

# Copy package manifests and install production dependencies
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy application source code
COPY server.js ./

# Use unprivileged node user for container security
USER node

# Expose WebSocket & HTTP port
EXPOSE 8080

# Automated health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Start the server
CMD ["node", "server.js"]
