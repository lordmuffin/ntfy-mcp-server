#!/bin/bash
export NTFY_TOPIC=cowork
export NTFY_URL=https://ntfy.apj.dev/
export NODE_ENV=production
export FORCE_COLOR=0
cd /home/lordmuffin/git/ntfy-mcp-server && node dist/index.js