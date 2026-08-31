# ==============================================================================
# Lock-In Development Container Dockerfile
# Full Flutter + Dart + Node.js 20 Developer Environment
# ==============================================================================

FROM ghcr.io/cirruslabs/flutter:stable

# Switch to root for system installations
USER root

# Install Node.js 20 for backend development & testing
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs build-essential \
    && rm -rf /var/lib/apt/lists/*

# Pre-configure Flutter
RUN flutter config --enable-web \
    && flutter precache

# Set working directory
WORKDIR /workspace

# Return to cirrus developer user
USER cirrus
