FROM alpine:3.20

ARG NODE_MAJOR=22
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    UV_SYSTEM_PYTHON=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Multi-arch compatible: install Node.js, Python, pip, git; then python mcp-proxy and node tsx
RUN set -eux; \
    apk add --no-cache \
      nodejs npm python3 py3-pip git bash tini ca-certificates; \
    npm i -g --omit=dev tsx; \
    python3 -m pip install --no-cache-dir --upgrade pip; \
    python3 -m pip install --no-cache-dir mcp-proxy;

# Use tini for proper signal handling (PID 1)
ENTRYPOINT ["/sbin/tini","--","mcp-proxy"]

# Default to SSE on 3000; helm chart passes args; left here as documentation
EXPOSE 3000

LABEL org.opencontainers.image.source="https://github.com/icoretech/mcp-stdio-bridge" \
      org.opencontainers.image.description="Universal stdio→HTTP(SSE) bridge for MCP servers with Node (npx/tsx) and Python envs" \
      org.opencontainers.image.licenses="MIT"
