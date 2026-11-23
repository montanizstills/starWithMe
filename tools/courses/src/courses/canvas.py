"""A small Canvas REST client on the standard library.

The token is only ever sent in the Authorization header. Every message this
module produces goes through redact(), so neither the token nor the test
student password can reach stdout, stderr or a log.
"""
from __future__ import annotations

import json
import re
import socket
import time
import urllib.error
import urllib.parse
import urllib.request

_SECRETS: list = []


def register_secret(value) -> None:
    # Very short values would blank out ordinary words; Canvas tokens and the
    # generated passwords are long.
    if value and len(value) >= 6 and value not in _SECRETS:
        _SECRETS.append(value)


def redact(text) -> str:
    text = str(text)
    for s in _SECRETS:
        text = text.replace(s, "***")
    return text


class ConfigError(Exception):
    """Exit 2: missing variable, Canvas unreachable, or the token was refused."""


class CanvasError(Exception):
    """Exit 3: Canvas rejected part of the apply."""


class NotFound(CanvasError):
    pass


def _short(body: bytes) -> str:
    text = body.decode("utf-8", "replace")
    try:
        data = json.loads(text)
        if isinstance(data, dict):
            if "errors" in data:
                text = json.dumps(data["errors"])
            elif "message" in data:
                text = str(data["message"])
    except ValueError:
        text = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", text))
    return redact(text.strip())[:500]


class Canvas:
    def __init__(self, base_url: str, token: str, timeout: float = 60, retries: int = 2):
        self.base = base_url.rstrip("/")
        self.token = token
        self.timeout = timeout
        self.retries = retries
        register_secret(token)

    def url(self, path: str, params=None) -> str:
        url = path if path.startswith("http") else self.base + path
        if params:
            url += ("&" if "?" in url else "?") + urllib.parse.urlencode(params, doseq=True)
        return url

    def request(self, method: str, path: str, params=None, body=None, raw: bytes | None = None, content_type=None):
        url = self.url(path, params)
        headers = {"Authorization": f"Bearer {self.token}", "Accept": "application/json"}
        data = None
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        elif raw is not None:
            data = raw
            headers["Content-Type"] = content_type or "application/octet-stream"
        for attempt in range(self.retries + 1):
            req = urllib.request.Request(url, data=data, headers=headers, method=method)
            try:
                with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                    payload = resp.read()
                    link = resp.headers.get("Link", "")
                    return (json.loads(payload) if payload.strip() else None), link
            except urllib.error.HTTPError as e:
                payload = e.read()
                where = f"{method} {redact(urllib.parse.urlsplit(url).path)}"
                if e.code in (401, 403):
                    raise ConfigError(f"Canvas refused the token ({e.code}) on {where}: {_short(payload)}. Is CANVAS_API_TOKEN a site admin token for {self.base}?") from None
                if e.code == 404:
                    raise NotFound(f"{where}: not found") from None
                if e.code in (429, 502, 503, 504) and attempt < self.retries:
                    time.sleep(2 * (attempt + 1))
                    continue
                raise CanvasError(f"{where} failed with HTTP {e.code}: {_short(payload)}") from None
            except (urllib.error.URLError, socket.timeout, ConnectionError) as e:
                if attempt < self.retries and method == "GET":
                    time.sleep(2 * (attempt + 1))
                    continue
                reason = getattr(e, "reason", e)
                raise ConfigError(f"Canvas is unreachable at {self.base}: {redact(reason)}") from None
        raise AssertionError("unreachable")

    def get(self, path, params=None):
        return self.request("GET", path, params)[0]

    def get_or_none(self, path, params=None):
        try:
            return self.get(path, params)
        except NotFound:
            return None

    def get_all(self, path, params=None) -> list:
        params = dict(params or {})
        params.setdefault("per_page", 100)
        out: list = []
        url = path
        while url:
            data, link = self.request("GET", url, params)
            params = None  # the next link carries them
            if isinstance(data, list):
                out.extend(data)
            else:
                raise CanvasError(f"GET {path}: expected a list")
            url = _next_link(link)
        return out

    def post(self, path, body=None, params=None):
        return self.request("POST", path, params, body=body if body is not None else {})[0]

    def put(self, path, body):
        return self.request("PUT", path, body=body)[0]

    def delete(self, path):
        return self.request("DELETE", path)[0]


def _next_link(header: str):
    for part in header.split(","):
        m = re.search(r'<([^>]+)>\s*;\s*rel="next"', part)
        if m:
            return m.group(1)
    return None
