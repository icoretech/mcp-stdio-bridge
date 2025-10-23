FROM node:25-alpine

# Keep Python tooling isolated from system packages (PEP 668 compliant)
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.local/bin:${PATH}"

# Multi-arch compatible: install Python + git + tini; then install tsx and mcp-proxy (versioned)
ARG MCP_PROXY_VERSION="0.9.0"
COPY requirements.txt /tmp/requirements.txt
RUN set -eux; \
    apk add --no-cache python3 py3-pip git bash tini ca-certificates wget; \
    npm i -g --omit=dev tsx; \
    # Install uv statically (musl) via GitHub release tarball
    case "${TARGETARCH:-amd64}" in \
      amd64) UV_ARCH=x86_64 ;; \
      arm64) UV_ARCH=aarch64 ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    UV_URL="https://github.com/astral-sh/uv/releases/latest/download/uv-${UV_ARCH}-unknown-linux-musl.tar.gz"; \
    wget -qO /tmp/uv.tar.gz "$UV_URL"; \
    mkdir -p /opt/uvtmp; \
    tar -xzf /tmp/uv.tar.gz -C /opt/uvtmp; \
    if [ -f /opt/uvtmp/uv ]; then mv /opt/uvtmp/uv /usr/local/bin/uv; \
    else f=$(find /opt/uvtmp -type f -name uv | head -n1); [ -n "$f" ] && mv "$f" /usr/local/bin/uv; fi; \
    chmod +x /usr/local/bin/uv; \
    # Provide a uvx wrapper that forwards to 'uv tool run' for ergonomic usage
    printf '%s\n' '#!/bin/sh' 'exec /usr/local/bin/uv tool run "$@"' > /usr/local/bin/uvx; \
    chmod +x /usr/local/bin/uvx; \
    rm -rf /opt/uvtmp /tmp/uv.tar.gz; \
    python3 -m venv /opt/mcp; \
    . /opt/mcp/bin/activate; \
    pip install --no-cache-dir --upgrade pip; \
    pip install --no-cache-dir -r /tmp/requirements.txt; \
    ln -s /opt/mcp/bin/mcp-proxy /usr/local/bin/mcp-proxy;

# Use tini for proper signal handling (PID 1) and run mcp-proxy (entrypoint provided by pipx)
ENTRYPOINT ["/sbin/tini","--","mcp-proxy"]

# Default to SSE on 3000; helm chart passes args; left here as documentation
EXPOSE 3000

LABEL org.opencontainers.image.source="https://github.com/icoretech/mcp-stdio-bridge" \
      org.opencontainers.image.description="Universal stdio→HTTP(SSE) bridge for MCP servers with Node (npx/tsx) and Python envs" \
      org.opencontainers.image.licenses="MIT"
