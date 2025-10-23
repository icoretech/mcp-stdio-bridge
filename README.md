# mcp-stdio-bridge

A tiny runtime image that keeps stdio-only Model Context Protocol (MCP) tools
alive and exposes them over HTTP/SSE.  It is designed to be dropped into a
Kubernetes Pod (for example through the `servers[].stdioBridge` block in the
`mcp-server` Helm chart), but it also works as a stand-alone container for
local testing.

## What is inside

| Runtime                | Notes                                                                 |
|------------------------|-----------------------------------------------------------------------|
| Node.js 25 + `npx`     | Launch Node based MCP servers (`npx chrome-devtools-mcp`, etc.).      |
| Python 3.12 + `pip`    | Base Python runtime for tools that need it.                           |
| `uv` + `uvx`           | Preinstalled musl build. The `uvx` wrapper forwards to
`uv tool run "$@"`, so commands such as `uvx mcp-server-reddit` just work. |
| `tsx`                  | Handy for TypeScript-first MCP servers.                               |
| `mcp-proxy 0.9.x`      | The bridge process that keeps the stdio tool alive and presents SSE.  |
| BusyBox utilities      | Used by init scripts; nothing exotic.                                 |

Both `amd64` and `arm64` images are built on every release.

## Quick start (local)

```bash
# Run a stdio-only MCP server with an SSE endpoint exposed at port 3000
docker run --rm -p 3000:3000 \
  ghcr.io/icoretech/mcp-stdio-bridge:0.3.1 \
  mcp-proxy --port 3000 -- npx chrome-devtools-mcp
```

The container downloads the tool on first start (using `npx`, `uvx`, etc.) and
keeps it alive.  Any arguments that follow `--` are passed to the stdio server.

### Using `uvx`

Because the image ships with `uvx` preconfigured you can launch Python-based
servers in one line:

```bash
# Start the Reddit MCP server and bridge it to SSE
docker run --rm ghcr.io/icoretech/mcp-stdio-bridge:0.3.1 \
  uvx mcp-server-reddit
```

This downloads the package (cached inside the container) and runs it through
`mcp-proxy` automatically.  Replace `mcp-server-reddit` with any uv-compatible
stdio tool.

## Kubernetes / Helm (stdio bridge)

When using the `mcp-server` Helm chart, enable the bridge per server:

```yaml
servers:
  - name: reddit
    port: 3000
    stdioBridge:
      enabled: true
      image: ghcr.io/icoretech/mcp-stdio-bridge
      tag: 0.3.1
      passEnvironment: true
      serverCommand: ["uvx", "mcp-server-reddit"]
      serverArgs: []
    register:
      enabled: false
```

The chart embeds `mcp-proxy`.  Setting `passEnvironment: true` forwards the
Pod environment to the child process, which is useful for API keys or other
configuration.

## Useful flags

You can pass any `mcp-proxy` flag before the `--` separator:

```bash
# Enforce a specific transport and allow all origins
docker run --rm ghcr.io/icoretech/mcp-stdio-bridge:0.3.1 \
  mcp-proxy --transport sse --allow-origin='*' --port 3000 -- \
  npx chrome-devtools-mcp
```

Common options:

- `--pass-environment` / `--no-pass-environment`
- `--cwd <path>` to change the working directory for the child process
- `--named-server` to expose multiple bridge targets from one container

Run `docker run --rm ghcr.io/icoretech/mcp-stdio-bridge:0.3.1 mcp-proxy --help`
for the full list.

## Release workflow

This repository uses Release Please:

1. Every commit and pull request triggers the *ci-build* workflow which builds
   (without pushing) and smoke-tests the runtime (`uv`, `uvx`, `node`,
   `python3`, `mcp-proxy`).
2. Merging the Release Please PR creates the tag `vX.Y.Z`.
3. The tag triggers the publish workflow which pushes the multi-arch image to
   `ghcr.io/icoretech/mcp-stdio-bridge` with tags `vX.Y.Z`, `vX.Y`, and
   `latest`.

## License

MIT (see LICENSE in the repo).
