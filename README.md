# mcp-stdio-bridge

Universal stdio → HTTP(SSE) bridge image for MCP servers on Kubernetes.

- Includes Node.js (with `npx`/`tsx`) and Python (`pip`).
- Entrypoint is `mcp-proxy`, converting stdio MCP servers to SSE over HTTP.
- Multi-arch (amd64/arm64) via GH Actions.

Refer to your Helm chart for usage.
