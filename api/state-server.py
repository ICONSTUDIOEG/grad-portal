#!/usr/bin/env python3
"""Minimal JSON state API for grad portal (bookings + project updates)."""
from __future__ import annotations

import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

STATE_PATH = os.environ.get("STATE_PATH", "/data/portal-state.json")
PORT = int(os.environ.get("PORT", "8080"))

DEFAULT = {
    "version": 1,
    "bookings": [],
    "projects": None,
    "professors": None,
    "updatedAt": None,
}


def read_state() -> dict:
    if not os.path.exists(STATE_PATH):
        return dict(DEFAULT)
    try:
        with open(STATE_PATH, encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return dict(DEFAULT)
        return data
    except (json.JSONDecodeError, OSError):
        return dict(DEFAULT)


def write_state(data: dict) -> None:
    os.makedirs(os.path.dirname(STATE_PATH) or ".", exist_ok=True)
    tmp = STATE_PATH + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp, STATE_PATH)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # quieter logs
        print(fmt % args)

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:
        if self.path not in ("/state", "/api/state"):
            self.send_error(404)
            return
        body = json.dumps(read_state(), ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        if self.path not in ("/state", "/api/state"):
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            incoming = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON")
            return
        if not isinstance(incoming, dict):
            self.send_error(400, "Expected JSON object")
            return

        current = read_state()
        if "bookings" in incoming and isinstance(incoming["bookings"], list):
            current["bookings"] = incoming["bookings"]
        if "projects" in incoming and isinstance(incoming["projects"], list):
            current["projects"] = incoming["projects"]
        if "professors" in incoming and isinstance(incoming["professors"], list):
            current["professors"] = incoming["professors"]
        from datetime import datetime, timezone

        current["version"] = 1
        current["updatedAt"] = datetime.now(timezone.utc).isoformat()
        write_state(current)

        body = b'{"ok":true}'
        self.send_response(200)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
