# Docker Usage — ntfy-mcp-server

## Prerequisites

- Docker 20.10 or later
- No other tools required

## Building the Image

```bash
docker build -t ntfy-mcp-server:latest .
```

To pin a specific version tag:

```bash
docker build -t ntfy-mcp-server:1.0.0 .
```

## Running the Server

MCP clients communicate with this server over **stdio**. Always pass `-i` (stdin open) and never `-t` (no pseudo-TTY — that would corrupt the binary framing of the JSON-RPC stream).

### Minimal run (public ntfy.sh, no auth)

```bash
docker run -i --rm \
  -e NTFY_DEFAULT_TOPIC=your_topic \
  ntfy-mcp-server:latest
```

### Full run with API key and persistent logs

```bash
docker run -i --rm \
  -e NTFY_DEFAULT_TOPIC=your_topic \
  -e NTFY_API_KEY=your_api_key_here \
  -e NTFY_BASE_URL=https://ntfy.sh \
  -e LOG_LEVEL=info \
  -v /host/path/to/logs:/app/logs \
  ntfy-mcp-server:latest
```

### Self-hosted ntfy server

```bash
docker run -i --rm \
  -e NTFY_BASE_URL=https://ntfy.example.com \
  -e NTFY_DEFAULT_TOPIC=alerts \
  -e NTFY_API_KEY=your_api_key_here \
  ntfy-mcp-server:latest
```

## MCP Client Integration

### Claude Desktop (`claude_desktop_config.json`)

```json
{
  "mcpServers": {
    "ntfy": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "NTFY_DEFAULT_TOPIC=your_topic",
        "-e", "NTFY_API_KEY=your_api_key_here",
        "ntfy-mcp-server:latest"
      ]
    }
  }
}
```

### Cline (VS Code extension) — `cline_mcp_settings.json`

```json
{
  "mcpServers": {
    "ntfy": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "NTFY_DEFAULT_TOPIC=your_topic",
        "-e", "NTFY_API_KEY=your_api_key_here",
        "ntfy-mcp-server:latest"
      ],
      "env": {}
    }
  }
}
```

## Environment Variable Reference

| Variable | Default in Image | Required | Description |
|---|---|---|---|
| `NTFY_BASE_URL` | `https://ntfy.sh` | No | ntfy server endpoint; override for self-hosted instances |
| `NTFY_DEFAULT_TOPIC` | *(unset)* | Recommended | Topic used when the tool call doesn't specify one |
| `NTFY_API_KEY` | *(unset)* | No | Bearer token for authenticated ntfy topics |
| `NTFY_MAX_MESSAGE_SIZE` | `4096` | No | Maximum notification body size in bytes |
| `NTFY_MAX_RETRIES` | `3` | No | Retry attempts for failed publish requests |
| `NODE_ENV` | `production` | No | Node.js environment mode |
| `LOG_LEVEL` | `info` | No | Logging verbosity (`debug`, `info`, `warn`, `error`) |
| `LOG_FILE_DIR` | `/app/logs` | No | Directory for rotating log files; mount a volume here to persist |
| `RATE_LIMIT_WINDOW_MS` | `60000` | No | Rate-limit sliding window in milliseconds |
| `RATE_LIMIT_MAX_REQUESTS` | `100` | No | Maximum requests allowed per window |

**No credential files, OAuth tokens, or service account JSON are required.** This server is stateless.

## Security Notes

- The container runs as a non-root user (`mcp`, uid 1987) — no capabilities are needed.
- Secrets (`NTFY_API_KEY`, `NTFY_DEFAULT_TOPIC`) are injected at runtime via `-e`; they are never baked into the image.
- For production deployments, prefer Docker secrets or your orchestrator's secret store over `-e` flags, which appear in `docker inspect` output.

## Why `-i` and Not `-it`

`-i` keeps stdin open so the MCP client can write JSON-RPC requests to the container.  
`-t` allocates a pseudo-TTY, which adds control characters and line-ending translations that corrupt the binary framing of the JSON-RPC stream — never use it for stdio MCP servers.

## Verifying the Image

```bash
# Check the final image size (expect ~250-300 MB)
docker images ntfy-mcp-server

# Confirm the process runs as non-root
docker run --rm --entrypoint whoami ntfy-mcp-server:latest
# expected output: mcp

# Confirm the entrypoint (should be ["node","dist/index.js"], no wrapper)
docker inspect ntfy-mcp-server:latest | grep -A5 '"Entrypoint"'

# Smoke test: send an MCP initialize request and confirm a valid JSON-RPC response
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}\n' \
  | docker run -i --rm -e NTFY_DEFAULT_TOPIC=test ntfy-mcp-server:latest
```
