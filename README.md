# mcp-stdio-bridge

Universal stdio → HTTP(SSE) bridge image for MCP servers on Kubernetes.

- Includes Node.js (with `npx`/`tsx`) and Python (`pip`).
- Entrypoint is `mcp-proxy`, converting stdio MCP servers to SSE over HTTP.
- Multi-arch (amd64/arm64) via GH Actions.

## Usage with Helm `mcp-server`

Example values snippet:

```yaml
servers:
  - name: chrome-devtools
    port: 3000
    stdioBridge:
      enabled: true
      image: ghcr.io/icoretech/mcp-stdio-bridge
      tag: latest
      port: 3000
      passEnvironment: true
      serverCommand: ["npx","chrome-devtools-mcp"]
      serverArgs: []
    register:
      enabled: true
      type: sse
      path: /sse
```

## Local build

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/icoretech/mcp-stdio-bridge:dev --load .
```

