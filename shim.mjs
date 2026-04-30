#!/usr/bin/env node

import { spawn } from 'child_process';

const args = process.argv.slice(2);

// If the server is being called for a tool execution
// but the 'topic' or 'baseUrl' are missing in the logic,
// the environment variables we set in Claude Config will handle it
// IF the server supports them. Since it doesn't, we just execute.

spawn('node', ['/home/lordmuffin/git/ntfy-mcp-server/dist/index.js', ...args], {
  cwd: '/home/lordmuffin/git/ntfy-mcp-server',
  stdio: 'inherit',
  env: {
    ...process.env,
    NTFY_TOPIC: 'cowork',
    NTFY_URL: 'https://ntfy.apj.dev/',
    FORCE_COLOR: '0',
    NODE_ENV: 'production'
  }
});