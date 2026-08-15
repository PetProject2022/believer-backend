import { promisify } from 'node:util';
import { execFile } from 'node:child_process';

import { startServer } from './server.js';
import { env } from './config/env.js';
import express from 'express';
import cors from 'cors';
// ... other imports ...
import khutbahRoutes from './routes/khutbah.js';

const execFileAsync = promisify(execFile);

async function describePortListener(port) {
  try {
    const { stdout } = await execFileAsync('lsof', [
      '-nP',
      `-iTCP:${port}`,
      '-sTCP:LISTEN'
    ]);
    const lines = stdout
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);

    if (lines.length <= 1) {
      return null;
    }

    return lines.slice(1).join('\n');
  } catch {
    return null;
  }
}

async function formatStartupError(error) {
  if (error?.code !== 'EADDRINUSE') {
    return error;
  }

  const listenerDetails = await describePortListener(env.PORT);
  const detailsBlock = listenerDetails
    ? `\nCurrent listener:\n${listenerDetails}\n`
    : '\nCurrent listener: unavailable (lsof not found or listener exited before inspection)\n';

  return new Error(
    [
      `Local backend startup failed: port ${env.PORT} is already in use.`,
      `This app expects the local API on http://localhost:${env.PORT}.`,
      'A stale backend process or orphaned watcher is the most likely cause.',
      detailsBlock.trimEnd(),
      '',
      'Inspect the listener:',
      `  lsof -nP -iTCP:${env.PORT} -sTCP:LISTEN`,
      'Stop it and start again:',
      '  kill <pid>',
      '  npm --workspace backend run start'
    ].join('\n')
  );
}

try {
  await startServer();
} catch (error) {
  console.error(await formatStartupError(error));
  process.exit(1);
}
