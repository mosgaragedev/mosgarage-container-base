#!/usr/bin/env python3
"""Minimal debugging HTTP server.

Reports what the container sees — request headers, client address, resolved
environment — which makes it easy to check port forwarding, proxies and
ingress configuration from the browser or curl.

    debug-webserver [--port 7072] [--host 0.0.0.0]

Endpoints:
    GET /            HTML index
    GET /healthz     JSON health probe
    *   /echo        JSON dump of the request (method, path, headers)
    *   /env         JSON dump of selected environment variables
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import socket
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib.parse import parse_qs, urlparse

SAFE_ENV_PREFIXES = ("MOSGARAGE_", "CODE_SERVER_", "DEVCONTAINER")

INDEX_HTML = """<!doctype html>
<html lang="en">
  <head><meta charset="utf-8"><title>mosgarage debug webserver</title></head>
  <body style="font-family: system-ui, sans-serif; margin: 2rem">
    <h1>mosgarage debug webserver</h1>
    <ul>
      <li><a href="/healthz">/healthz</a> — health probe</li>
      <li><a href="/echo">/echo</a> — request as JSON</li>
      <li><a href="/env">/env</a> — container environment</li>
    </ul>
  </body>
</html>
"""


def host_info() -> dict[str, Any]:
    return {
        "hostname": socket.gethostname(),
        "platform": platform.platform(),
        "python": platform.python_version(),
        "user": os.environ.get("USER", "unknown"),
        "time": datetime.now(timezone.utc).isoformat(),
    }


class DebugHandler(BaseHTTPRequestHandler):
    server_version = "mosgarage-debug/1.0"

    def do_GET(self) -> None:  # noqa: N802 (http.server naming)
        parsed = urlparse(self.path)
        route = parsed.path.rstrip("/") or "/"

        if route == "/":
            self._respond(200, "text/html; charset=utf-8", INDEX_HTML)
            return

        if route == "/healthz":
            self._respond(200, "application/json", json.dumps({"status": "ok", **host_info()}))
            return

        if route == "/env":
            env = {
                key: value
                for key, value in sorted(os.environ.items())
                if key.startswith(SAFE_ENV_PREFIXES)
            }
            self._respond(200, "application/json", json.dumps({"env": env, **host_info()}))
            return

        if route == "/echo":
            body = {
                "method": self.command,
                "path": parsed.path,
                "query": parse_qs(parsed.query),
                "client": self.client_address[0],
                "headers": dict(self.headers.items()),
                **host_info(),
            }
            self._respond(200, "application/json", json.dumps(body, indent=2))
            return

        self._respond(404, "application/json", json.dumps({"error": "not found", "path": parsed.path}))

    def do_HEAD(self) -> None:  # noqa: N802
        self._respond(200, "text/plain; charset=utf-8", "")

    def do_POST(self) -> None:  # noqa: N802
        length = int(self.headers.get("Content-Length") or 0)
        payload = self.rfile.read(length).decode("utf-8", "replace") if length else ""
        body = {
            "method": self.command,
            "path": urlparse(self.path).path,
            "content_type": self.headers.get("Content-Type"),
            "body": payload[:8192],
            **host_info(),
        }
        self._respond(200, "application/json", json.dumps(body, indent=2))

    def _respond(self, status: int, content_type: str, payload: str) -> None:
        encoded = payload.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(encoded)

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"[debug-webserver] {self.address_string()} {fmt % args}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="mosgarage debug webserver")
    parser.add_argument("--host", default=os.environ.get("DEBUG_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("DEBUG_PORT", "7072")))
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), DebugHandler)
    print(f"[debug-webserver] listening on http://{args.host}:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
