---
description: "Start Astro dev server. Blog on port 12345 (default), reading on port 12346 with --reading flag."
user_invocable: true
argument-hint: "[--reading]"
---

Two configs: blog (21 pages, port 12345) and reading (490 pages, port 12346). Default is blog.

Run these steps sequentially:

1. Kill any existing process on the target port:
```bash
# If --reading: port 12346. Otherwise: port 12345.
PORT=${READING:+12346}; PORT=${PORT:-12345}
for port in $PORT $((PORT+1)); do PID=$(lsof -ti:$port 2>/dev/null); if [ -n "$PID" ]; then kill -9 $PID 2>/dev/null; echo "Killed PID(s) on port $port: $PID"; fi; done; sleep 1
```

2. Start the dev server in the background:
```bash
# If argument contains --reading or "reading":
pnpm run dev:reading
# Otherwise:
pnpm run dev
```
Run this command in the background.

3. Wait for the server to be ready, then verify it responds:
```bash
for i in $(seq 1 15); do curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ 2>/dev/null && break; sleep 1; done
curl -s -o /dev/null -w "Astro dev server verified: HTTP %{http_code} on port $PORT\n" http://localhost:$PORT/
```
