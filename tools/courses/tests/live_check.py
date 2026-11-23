"""Check an applied course on a real Canvas (SWM-205 acceptance criteria).

  python tools/courses/tests/live_check.py <course-folder> <apply-report.json>

Uses CANVAS_URL (default http://localhost:3000), CANVAS_API_TOKEN and
TEST_STUDENT_PASSWORD. Checks that the course and its quizzes are published
Classic Quizzes, that fenced code is preformatted in pages and questions, and
that the test student can log in with the password and sees the course.
Standard library only; secrets are never printed. Exit 0 when all pass.
"""
from __future__ import annotations

import http.cookiejar
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import yaml


def main(folder: str, report_path: str) -> int:
    base = os.environ.get("CANVAS_URL", "http://localhost:3000").rstrip("/")
    token = os.environ["CANVAS_API_TOKEN"]
    password = os.environ["TEST_STUDENT_PASSWORD"]
    report = json.loads(Path(report_path).read_text())
    course_yml = yaml.safe_load((Path(folder) / "course.yml").read_text())
    cid = report["course_id"]
    failures = []

    def check(ok, what):
        print(f"{'PASS' if ok else 'FAIL'}: {what}")
        if not ok:
            failures.append(what)

    def api(path):
        req = urllib.request.Request(base + path, headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read())

    course = api(f"/api/v1/courses/{cid}")
    check(course["workflow_state"] == "available", f"course {cid} is published")
    check(course.get("sis_course_id") == report["course"], "course SIS id is the folder name")

    fenced = sum(1 for p in Path(folder).glob("[0-9][0-9][0-9]-*.md") if "```" in p.read_text())
    modules = api(f"/api/v1/courses/{cid}/modules?include[]=items&per_page=100")
    with_pre = 0
    for m in modules:
        check(m.get("published") is True, f"module {m['name']!r} is published")
        for item in m.get("items") or []:
            if item["type"] == "Page":
                ref = f"page_id:{item['content_id']}" if item.get("content_id") else item["page_url"]
                page = api(f"/api/v1/courses/{cid}/pages/{ref}")
                check(page.get("published") is True, f"page {page['title']!r} is published")
                with_pre += "<pre" in (page.get("body") or "")
    check(with_pre >= fenced, f"fenced code is preformatted: {with_pre} page(s) with <pre>, {fenced} note(s) with fences")
    for q in report.get("quizzes", []):
        quiz = api(f"/api/v1/courses/{cid}/quizzes/{q['canvas_id']}")
        check(quiz.get("published") is True, f"quiz {q['title']!r} is published")
        questions = api(f"/api/v1/courses/{cid}/quizzes/{q['canvas_id']}/questions?per_page=100")
        check(len(questions) > 0, f"quiz {q['title']!r} has {len(questions)} question(s) (Classic Quizzes API)")
        print(f"  {sum('<pre' in (x.get('question_text') or '') for x in questions)} question(s) with preformatted code")

    for user in course_yml.get("sis_users") or []:
        enr = api(f"/api/v1/courses/{cid}/enrollments?sis_user_id[]={urllib.parse.quote(user['user_id'])}")
        check(any(e["enrollment_state"] == "active" for e in enr), f"{user['user_id']} enrollment is active")
        check(student_sees_course(base, user["login_id"], password, cid), f"{user['login_id']} logs in with TEST_STUDENT_PASSWORD and sees the course")

    print(f"{len(failures)} failure(s)")
    return 1 if failures else 0


def student_sees_course(base: str, login: str, password: str, course_id) -> bool:
    jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    html = opener.open(base + "/login/canvas", timeout=60).read().decode()
    m = re.search(r'name="authenticity_token" value="([^"]+)"', html)
    if not m:
        print("  no authenticity_token on the login page")
        return False
    form = urllib.parse.urlencode({
        "authenticity_token": m.group(1),
        "pseudonym_session[unique_id]": login,
        "pseudonym_session[password]": password,
        "pseudonym_session[remember_me]": "0",
    }).encode()
    try:
        resp = opener.open(urllib.request.Request(base + "/login/canvas", data=form), timeout=60)
    except urllib.error.HTTPError as e:  # Canvas answers a failed login with 400
        print(f"  login was refused (HTTP {e.code})")
        return False
    if "/login" in urllib.parse.urlsplit(resp.geturl()).path:
        print("  login was refused")
        return False
    body = opener.open(base + "/api/v1/courses?per_page=100", timeout=60).read().decode()
    courses = json.loads(body.removeprefix("while(1);"))
    return any(c.get("id") == course_id for c in courses)


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:3]))
