FROM node:25-alpine

# Keep Python tooling isolated from system packages (PEP 668 compliant)
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.local/bin:${PATH}"

# Multi-arch compatible: install Python + pipx, git, tini; then install tsx and mcp-proxy
RUN set -eux; \
    apk add --no-cache python3 py3-pip git bash tini ca-certificates; \
    npm i -g --omit=dev tsx; \
    python3 -m venv /opt/mcp; \
    . /opt/mcp/bin/activate; \
    pip install --no-cache-dir --upgrade pip; \
    pip install --no-cache-dir mcp-proxy; \
    ln -s /opt/mcp/bin/mcp-proxy /usr/local/bin/mcp-proxy;

# Use tini for proper signal handling (PID 1) and run mcp-proxy (entrypoint provided by pipx)
ENTRYPOINT ["/sbin/tini","--","mcp-proxy"]

# Default to SSE on 3000; helm chart passes args; left here as documentation
EXPOSE 3000

LABEL org.opencontainers.image.source="https://github.com/icoretech/mcp-stdio-bridge" \
      org.opencontainers.image.description="Universal stdio→HTTP(SSE) bridge for MCP servers with Node (npx/tsx) and Python envs" \
      org.opencontainers.image.licenses="MIT"
