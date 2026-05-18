# ---- Builder Stage ----
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package manifests first for layer-cache efficiency
COPY package.json package-lock.json ./

# Install all dependencies (devDeps required for TypeScript compilation)
RUN npm ci

# Copy source files needed for the build
COPY tsconfig.json ./
COPY src/ ./src/
COPY scripts/ ./scripts/

# Compile TypeScript → dist/ and strip devDependencies
RUN npm run build && npm prune --omit=dev


# ---- Final Stage ----
FROM node:22-alpine

# Create a non-root system user/group for security compliance
RUN addgroup --system --gid 1987 mcp \
 && adduser  --system --uid 1987 --ingroup mcp --no-create-home mcp

WORKDIR /app

# Pre-create log directory with correct ownership
RUN mkdir -p /app/logs && chown mcp:mcp /app /app/logs

# Copy only the production artifacts from the builder
COPY --from=builder --chown=mcp:mcp /app/package.json   ./package.json
COPY --from=builder --chown=mcp:mcp /app/node_modules   ./node_modules
COPY --from=builder --chown=mcp:mcp /app/dist           ./dist

USER mcp

# Non-sensitive runtime defaults; secrets (NTFY_API_KEY, NTFY_DEFAULT_TOPIC)
# must be injected at runtime via -e flags — never baked into the image.
ENV NODE_ENV=production \
    LOG_LEVEL=info \
    NTFY_BASE_URL=https://ntfy.sh \
    LOG_FILE_DIR=/app/logs

# Direct entrypoint — no wrapper. PID 1 is the server process so that
# stdio (the MCP protocol channel) flows through unmodified.
ENTRYPOINT ["node", "dist/index.js"]
