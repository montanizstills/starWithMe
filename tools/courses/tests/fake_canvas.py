"""An in-memory stand-in for the parts of the Canvas API that `courses apply`
uses, so apply can be tested without a Canvas server. It mimics the Canvas
behaviour that matters for re-runs: sanitized HTML comes back with extra
attributes and different whitespace, page URLs come from titles, lists are
paginated with Link headers, and SIS Imports finish asynchronously."""
from __future__ import annotations

import csv
import io
import itertools
import json
import re
import threading
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

PER_PAGE = 3  # small, so pagination is exercised


def sanitize(html: str) -> str:
    """Roughly what Canvas's sanitizer does to our HTML: attributes added,
    whitespace between tags changed, entities respelled."""
    if not html:
        return html
    html = re.sub(r"<p>", '<p dir="ltr">', html)
    html = re.sub(r">\s*\n\s*<", ">\n  <", html)
    return html.replace("&quot;", "&#34;")


def slug(title: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")


class State:
    def __init__(self, token: str):
        self.token = token
        self.ids = itertools.count(100)
        self.courses: dict = {}
        self.users: dict = {}
        self.passwords: dict = {}
        self.enrollments: list = []
        self.modules: dict = {}  # course id -> [module]
        self.items: dict = {}  # module id -> [item]
        self.pages: dict = {}  # course id -> {url: page}
        self.quizzes: dict = {}  # course id -> [quiz]
        self.questions: dict = {}  # quiz id -> [question]
        self.imports: dict = {}
        self.requests: list = []
        self.sis_payloads: list = []

    def nid(self) -> int:
        return next(self.ids)


class Handler(BaseHTTPRequestHandler):
    state: State

    def log_message(self, *a):
        pass

    # -- plumbing -------------------------------------------------------
    def _send(self, code, data=None, link=None):
        body = json.dumps(data).encode() if data is not None else b""
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        if link:
            self.send_header("Link", link)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _list(self, rows, query):
        page = int(query.get("page", ["1"])[0])
        per = min(int(query.get("per_page", ["10"])[0]), PER_PAGE)
        chunk = rows[(page - 1) * per: page * per]
        link = None
        if page * per < len(rows):
            q = {k: v for k, v in query.items() if k != "page"}
            q["page"] = [str(page + 1)]
            qs = "&".join(f"{k}={x}" for k, vs in q.items() for x in vs)
            link = f'<http://{self.headers["Host"]}{urlsplit(self.path).path}?{qs}>; rel="next"'
        self._send(200, chunk, link)

    def _body(self):
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n) if n else b""
        if self.headers.get("Content-Type", "").startswith("application/json"):
            return json.loads(raw or b"{}")
        return raw

    def handle_any(self, method):
        st = self.state
        if self.headers.get("Authorization") != f"Bearer {st.token}":
            return self._send(401, {"errors": [{"message": "Invalid access token."}]})
        parts = urlsplit(self.path)
        q = parse_qs(parts.query)
        path = parts.path
        body = self._body() if method in ("POST", "PUT") else None
        st.requests.append((method, path))
        with LOCK:
            return self.route(method, path, q, body)

    def do_GET(self):
        self.handle_any("GET")

    def do_POST(self):
        self.handle_any("POST")

    def do_PUT(self):
        self.handle_any("PUT")

    def do_DELETE(self):
        self.handle_any("DELETE")

    # -- routes ---------------------------------------------------------
    def route(self, method, path, q, body):
        st = self.state
        m = re.fullmatch
        if method == "GET" and path == "/api/v1/users/self":
            return self._send(200, {"id": 1, "name": "admin"})
        if r := m(r"/api/v1/users/sis_user_id:(.+)", path):
            u = st.users.get(r.group(1))
            return self._send(200, u) if u else self._send(404, {"errors": [{"message": "not found"}]})
        if r := m(r"/api/v1/courses/sis_course_id:(.+)", path):
            c = next((c for c in st.courses.values() if c["sis_course_id"] == r.group(1)), None)
            return self._send(200, c) if c else self._send(404, {"errors": [{"message": "not found"}]})
        if r := m(r"/api/v1/accounts/(\d+)/sis_imports", path):
            if method == "POST":
                return self.sis_import(body, q)
        if r := m(r"/api/v1/accounts/(\d+)/sis_imports/(\d+)", path):
            job = st.imports[int(r.group(2))]
            job["polls"] += 1
            if job["polls"] >= 2:
                job["workflow_state"] = "imported"
            return self._send(200, job)

        r = m(r"/api/v1/courses/(\d+)(/.*)?", path)
        if not r:
            return self._send(404, {"errors": [{"message": "no route"}]})
        cid, rest = int(r.group(1)), r.group(2) or ""
        course = st.courses.get(cid)
        if course is None:
            return self._send(404, {"errors": [{"message": "no course"}]})
        if rest == "":
            if method == "PUT":
                c = body["course"]
                for k in ("name", "course_code", "default_view", "public_description"):
                    if k in c:
                        course[k] = c[k]
                if c.get("event") == "offer":
                    course["workflow_state"] = "available"
            return self._send(200, course)
        if rest == "/enrollments":
            uid = int(q.get("user_id", ["0"])[0])
            rows = [e for e in st.enrollments if e["course_id"] == cid and e["user_id"] == uid]
            return self._list(rows, q)
        if rest == "/modules":
            mods = st.modules.setdefault(cid, [])
            if method == "POST":
                mod = {"id": st.nid(), "name": body["module"]["name"], "position": body["module"].get("position", len(mods) + 1), "published": False}
                mods.append(mod)
                return self._send(200, mod)
            return self._list(sorted(mods, key=lambda x: x["position"]), q)
        if r := m(r"/modules/(\d+)", rest):
            mod = next(x for x in st.modules[cid] if x["id"] == int(r.group(1)))
            mod.update(body["module"])
            return self._send(200, mod)
        if r := m(r"/modules/(\d+)/items", rest):
            items = st.items.setdefault(int(r.group(1)), [])
            pages = {p["page_id"]: p for p in st.pages.get(cid, {}).values()}
            if method == "POST":
                it = dict(body["module_item"], id=st.nid())
                if it["type"] == "Page":  # Canvas links the item to the page itself, not its URL
                    it["content_id"] = st.pages[cid][it.pop("page_url")]["page_id"]
                items.append(it)
                return self._send(200, it)
            # Like Canvas: a Page item shows the page's current URL, not its id
            shown = [{**{k: v for k, v in i.items() if k != "content_id"}, "page_url": pages[i["content_id"]]["url"]}
                     if i["type"] == "Page" else i for i in items]
            return self._list(shown, q)
        if rest == "/pages" and method == "POST":
            wp = body["wiki_page"]
            pages = st.pages.setdefault(cid, {})
            url = slug(wp["title"])
            page = {"page_id": st.nid(), "url": url, "title": wp["title"], "body": sanitize(wp.get("body", "")), "published": wp.get("published", False)}
            pages[url] = page
            return self._send(200, page)
        if r := m(r"/pages/([^/]+)", rest):
            key = r.group(1)
            if key.startswith("page_id:"):
                page = next((p for p in st.pages.get(cid, {}).values() if p["page_id"] == int(key[8:])), None)
            else:
                page = st.pages.get(cid, {}).get(key)
            if page is None:
                return self._send(404, {"errors": [{"message": "page not found"}]})
            if method == "PUT":
                wp = body["wiki_page"]
                if "body" in wp:
                    page["body"] = sanitize(wp["body"])
                for k in ("title", "published"):
                    if k in wp:
                        page[k] = wp[k]
                if "title" in wp:  # Canvas renames the URL with the title
                    del st.pages[cid][page["url"]]
                    page["url"] = slug(wp["title"])
                    st.pages[cid][page["url"]] = page
            return self._send(200, page)
        if rest == "/quizzes":
            quizzes = st.quizzes.setdefault(cid, [])
            if method == "POST":
                qz = dict(body["quiz"], id=st.nid())
                qz["description"] = sanitize(qz.get("description", ""))
                quizzes.append(qz)
                st.questions[qz["id"]] = []
                return self._send(200, qz)
            return self._list(quizzes, q)
        if r := m(r"/quizzes/(\d+)", rest):
            qz = next((x for x in st.quizzes.get(cid, []) if x["id"] == int(r.group(1))), None)
            if qz is None:
                return self._send(404, {"errors": [{"message": "quiz not found"}]})
            if method == "PUT":
                upd = dict(body["quiz"])
                if "description" in upd:
                    upd["description"] = sanitize(upd["description"])
                qz.update(upd)
                if upd.get("published"):
                    qz["publish_count"] = qz.get("publish_count", 0) + 1
            return self._send(200, qz)
        if r := m(r"/quizzes/(\d+)/questions", rest):
            qs = st.questions[int(r.group(1))]
            if method == "POST":
                qq = self.question(body["question"], st.nid())
                qs.append(qq)
                return self._send(200, qq)
            return self._list(qs, q)
        if r := m(r"/quizzes/(\d+)/questions/(\d+)", rest):
            qs = st.questions[int(r.group(1))]
            idx = next(i for i, x in enumerate(qs) if x["id"] == int(r.group(2)))
            if method == "DELETE":
                qs.pop(idx)
                return self._send(204)
            qs[idx] = self.question(body["question"], qs[idx]["id"])
            return self._send(200, qs[idx])
        return self._send(404, {"errors": [{"message": "no route " + rest}]})

    @staticmethod
    def question(p, qid):
        return {
            "id": qid,
            "position": p["position"],
            "question_name": p["question_name"],
            "question_type": p["question_type"],
            "question_text": sanitize(p["question_text"]),
            "points_possible": float(p["points_possible"]),
            "correct_comments": p.get("correct_comments", ""),
            "incorrect_comments": p.get("incorrect_comments", ""),
            "neutral_comments": p.get("neutral_comments", ""),
            "answers": [
                {"id": i, "text": a["answer_text"], "html": sanitize(a.get("answer_html", "")), "weight": a["answer_weight"], "comments": a.get("answer_comments", "")}
                for i, a in enumerate(p["answers"])
            ],
        }

    def sis_import(self, raw: bytes, q):
        st = self.state
        assert q.get("extension") == ["zip"], q
        st.sis_payloads.append(raw)
        z = zipfile.ZipFile(io.BytesIO(raw))
        names = set(z.namelist())

        def rows(name):
            return list(csv.DictReader(io.StringIO(z.read(name).decode()))) if name in names else []

        for c in rows("courses.csv"):
            cid = st.nid()
            st.courses[cid] = {"id": cid, "sis_course_id": c["course_id"], "name": c["long_name"], "course_code": c["short_name"],
                               "workflow_state": "unpublished", "default_view": "modules", "public_description": None}
        for u in rows("users.csv"):
            existing = st.users.get(u["user_id"])
            uid = existing["id"] if existing else st.nid()
            st.users[u["user_id"]] = {"id": uid, "sis_user_id": u["user_id"], "login_id": u["login_id"], "name": u.get("full_name", "")}
            st.passwords[u["login_id"]] = u["password"]
        for e in rows("enrollments.csv"):
            course = next(c for c in st.courses.values() if c["sis_course_id"] == e["course_id"])
            user = st.users[e["user_id"]]
            st.enrollments.append({"id": st.nid(), "course_id": course["id"], "user_id": user["id"], "type": "StudentEnrollment", "enrollment_state": e["status"]})
        jid = st.nid()
        st.imports[jid] = {"id": jid, "workflow_state": "created", "polls": 0}
        return self._send(200, st.imports[jid])


LOCK = threading.Lock()


class FakeCanvas:
    def __init__(self, token="test-token-123"):
        self.state = State(token)
        handler = type("H", (Handler,), {"state": self.state})
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.url = f"http://127.0.0.1:{self.server.server_address[1]}"
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *a):
        self.server.shutdown()
        self.server.server_close()
