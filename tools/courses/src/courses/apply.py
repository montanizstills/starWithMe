"""courses apply: make Canvas match a course folder (SWM-205).

Structure (course, test students, enrollments) goes through SIS Import, and
only when something is missing. Content goes through the REST API, one module
per lesson in number order, holding the lesson page and, when the lesson has a
reviewed quiz, its Classic Quiz. Re-runs match on: the course SIS id; the
module at the lesson's position (renamed if its title changed); the page and
quiz items inside that module, or a quiz with the same title. Nothing is
deleted except quiz questions past the end of the file.
"""
from __future__ import annotations

import sys

from . import render
from .canvas import Canvas, NotFound
from .model import Course, Lesson, Quiz
from .sis import build_zip, run_import

COURSE_FIELDS = ("name", "course_code", "default_view", "public_description")


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


class Applier:
    def __init__(self, canvas: Canvas, course: Course, target: str, account_id: str = "1", password: str | None = None, reset_password: bool = False):
        self.c = canvas
        self.course = course
        self.target = target
        self.account_id = account_id
        self.password = password
        self.reset_password = reset_password
        self.changes: list = []
        self.unchanged = 0
        self.course_id = None
        self.quizzes: list | None = None
        self.modules: list = []
        self.course_created = False

    # -- report ---------------------------------------------------------
    def change(self, action: str, type_: str, id_: str, canvas_id) -> None:
        self.changes.append({"action": action, "type": type_, "id": id_, "canvas_id": canvas_id})
        log(f"{action} {type_} {id_}")

    def report(self) -> dict:
        created = sum(1 for c in self.changes if c["action"] == "create")
        return {
            "course": self.course.sis_id,
            "target": self.target,
            "course_id": self.course_id,
            "changes": self.changes,
            "skipped": self.course.skipped,
            "quizzes": [
                {"id": l.id, "title": l.quiz.title, "canvas_id": l.quiz_canvas_id}
                for l in self.course.lessons if l.quiz is not None and getattr(l, "quiz_canvas_id", None)
            ],
            "summary": {"created": created, "updated": len(self.changes) - created, "unchanged": self.unchanged},
        }

    # -- run ------------------------------------------------------------
    def run(self) -> dict:
        self.c.get("/api/v1/users/self")  # fails fast with exit 2 on a bad token or URL
        self.structure()
        self.course_settings()
        self.modules = sorted(self.c.get_all(f"/api/v1/courses/{self.course_id}/modules"), key=lambda m: m["position"])
        for position, lesson in enumerate(self.course.lessons, start=1):
            self.lesson(position, lesson)
        if len(self.modules) > len(self.course.lessons):
            extra = ", ".join(m["name"] for m in self.modules[len(self.course.lessons):])
            log(f"note: Canvas has modules past the last lesson, left as they are: {extra}")
        return self.report()

    # -- structure: SIS Import -----------------------------------------
    def structure(self) -> None:
        course = self.course
        sis = course.sis_id
        existing = self.c.get_or_none(f"/api/v1/courses/sis_course_id:{sis}")
        users = {}
        for u in course.sis_users:
            users[u["user_id"]] = self.c.get_or_none(f"/api/v1/users/sis_user_id:{u['user_id']}")

        course_rows, user_rows, enroll_rows = [], [], []
        if existing is None:
            course_rows.append({"course_id": sis, "short_name": course.course_code or course.name, "long_name": course.name, "status": "active"})
        else:
            self.unchanged += 1
        for u in course.sis_users:
            if users[u["user_id"]] is None or self.reset_password:
                user_rows.append(u)
            else:
                self.unchanged += 1
            enrolled = False
            if existing is not None and users[u["user_id"]] is not None:
                rows = self.c.get_all(
                    f"/api/v1/courses/{existing['id']}/enrollments",
                    {"user_id": users[u["user_id"]]["id"], "type[]": "StudentEnrollment", "state[]": "active"},
                )
                enrolled = any(r.get("enrollment_state") == "active" for r in rows)
            if enrolled:
                self.unchanged += 1
            else:
                enroll_rows.append({"course_id": sis, "user_id": u["user_id"], "role": "student", "status": "active"})

        if course_rows or user_rows or enroll_rows:
            payload = build_zip(course_rows, user_rows, enroll_rows, self.password)
            try:
                run_import(self.c, self.account_id, payload)
            finally:
                del payload
            existing = existing or self.c.get(f"/api/v1/courses/sis_course_id:{sis}")
            if course_rows:
                self.change("create", "course", sis, existing["id"])
            for u in user_rows:
                was_new = users[u["user_id"]] is None
                users[u["user_id"]] = self.c.get(f"/api/v1/users/sis_user_id:{u['user_id']}")
                self.change("create" if was_new else "update", "user", u["user_id"], users[u["user_id"]]["id"])
            for e in enroll_rows:
                rows = self.c.get_all(
                    f"/api/v1/courses/{existing['id']}/enrollments",
                    {"user_id": users[e["user_id"]]["id"], "type[]": "StudentEnrollment"},
                )
                self.change("create", "enrollment", f"{e['user_id']}@{sis}", rows[0]["id"] if rows else None)
        self.course_id = existing["id"]
        self.course_created = bool(course_rows)

    def course_settings(self) -> None:
        current = self.c.get(f"/api/v1/courses/{self.course_id}", {"include[]": ["public_description"]})
        want = {k: v for k, v in self.course.settings.items() if k in COURSE_FIELDS}
        diff = {k: v for k, v in want.items() if (current.get(k) or "") != (v or "")}
        if current.get("workflow_state") != "available":
            diff["event"] = "offer"  # publish the course
        if diff:
            self.c.put(f"/api/v1/courses/{self.course_id}", {"course": diff})
            if not self.course_created:
                self.unchanged -= 1  # structure() counted it as unchanged
                self.change("update", "course", self.course.sis_id, self.course_id)

    # -- content: REST API ---------------------------------------------
    def lesson(self, position: int, lesson: Lesson) -> None:
        cid = self.course_id
        module = self.modules[position - 1] if position <= len(self.modules) else None
        if module is None:
            module = self.c.post(f"/api/v1/courses/{cid}/modules", {"module": {"name": lesson.title, "position": position}})
            self.modules.append(module)
            self.c.put(f"/api/v1/courses/{cid}/modules/{module['id']}", {"module": {"published": True}})
            self.change("create", "module", lesson.id, module["id"])
            items = []
        else:
            diff = {}
            if module.get("name") != lesson.title:
                diff["name"] = lesson.title
            if not module.get("published", True):
                diff["published"] = True
            if diff:
                self.c.put(f"/api/v1/courses/{cid}/modules/{module['id']}", {"module": diff})
                self.change("update", "module", lesson.id, module["id"])
            else:
                self.unchanged += 1
            items = self.c.get_all(f"/api/v1/courses/{cid}/modules/{module['id']}/items")

        self.page(module, items, lesson)
        if lesson.quiz is not None:
            self.quiz(module, items, lesson)

    def page(self, module: dict, items: list, lesson: Lesson) -> None:
        cid = self.course_id
        body = render.md_to_html(lesson.body)
        item = next((i for i in items if i.get("type") == "Page"), None)
        page = None
        if item is not None:
            # By id first: a page's URL changes when its title does.
            ref = f"page_id:{item['content_id']}" if item.get("content_id") else item.get("page_url")
            try:
                page = self.c.get(f"/api/v1/courses/{cid}/pages/{ref}")
            except NotFound:
                page = None
        if page is None:
            page = self.c.post(f"/api/v1/courses/{cid}/pages", {"wiki_page": {"title": lesson.title, "body": body, "published": True}})
            self.change("create", "page", lesson.id, page.get("page_id"))
            if item is None:
                self.c.post(f"/api/v1/courses/{cid}/modules/{module['id']}/items",
                            {"module_item": {"type": "Page", "page_url": page["url"], "position": 1}})
            return
        diff = {}
        if page.get("title") != lesson.title:
            diff["title"] = lesson.title
        if not render.same_html(page.get("body"), body):
            diff["body"] = body
        if not page.get("published"):
            diff["published"] = True
        if diff:
            self.c.put(f"/api/v1/courses/{cid}/pages/{page['url']}", {"wiki_page": diff})
            self.change("update", "page", lesson.id, page.get("page_id"))
        else:
            self.unchanged += 1

    def find_quiz(self, items: list, quiz: Quiz):
        cid = self.course_id
        item = next((i for i in items if i.get("type") == "Quiz"), None)
        if item is not None:
            try:
                return self.c.get(f"/api/v1/courses/{cid}/quizzes/{item['content_id']}"), item
            except NotFound:
                pass
        if self.quizzes is None:
            self.quizzes = self.c.get_all(f"/api/v1/courses/{cid}/quizzes")
        same = [q for q in self.quizzes if q.get("title") == quiz.title]
        return (self.c.get(f"/api/v1/courses/{cid}/quizzes/{same[0]['id']}") if same else None), item

    def quiz(self, module: dict, items: list, lesson: Lesson) -> None:
        cid = self.course_id
        spec = lesson.quiz
        settings = {k: v for k, v in spec.settings.items() if k != "published"}
        publish = spec.settings.get("published", True)
        description = render.md_to_html(spec.description)
        quiz, item = self.find_quiz(items, spec)
        created = quiz is None
        if created:
            quiz = self.c.post(f"/api/v1/courses/{cid}/quizzes",
                               {"quiz": {"title": spec.title, "description": description, **settings, "published": False}})
            self.change("create", "quiz", lesson.id, quiz["id"])
        else:
            diff = {}
            if quiz.get("title") != spec.title:
                diff["title"] = spec.title
            if not render.same_html(quiz.get("description"), description):
                diff["description"] = description
            for k, v in settings.items():
                if k in quiz and quiz[k] != v:
                    diff[k] = v
            if diff:
                self.c.put(f"/api/v1/courses/{cid}/quizzes/{quiz['id']}", {"quiz": diff})
                self.change("update", "quiz", lesson.id, quiz["id"])
            else:
                self.unchanged += 1
        lesson.quiz_canvas_id = quiz["id"]

        questions_changed = self.questions(quiz["id"], lesson)

        # Questions first, then publish. A published quiz is published again
        # after its questions change, so students get the new version.
        if publish and (created or questions_changed or not quiz.get("published")):
            self.c.put(f"/api/v1/courses/{cid}/quizzes/{quiz['id']}", {"quiz": {"published": True}})
            if not created and not quiz.get("published"):
                self.change("update", "quiz", lesson.id, quiz["id"])

        if item is None or item.get("content_id") != quiz["id"]:
            self.c.post(f"/api/v1/courses/{cid}/modules/{module['id']}/items",
                        {"module_item": {"type": "Quiz", "content_id": quiz["id"], "position": 2}})

    def questions(self, quiz_id, lesson: Lesson) -> bool:
        cid = self.course_id
        existing = sorted(self.c.get_all(f"/api/v1/courses/{cid}/quizzes/{quiz_id}/questions"), key=lambda q: q.get("position") or 0)
        changed = False
        for n, q in enumerate(lesson.quiz.questions):
            qid = f"{lesson.id}/q{n + 1}"
            payload = question_payload(q, n + 1)
            if n < len(existing):
                if question_matches(existing[n], payload):
                    self.unchanged += 1
                    continue
                self.c.put(f"/api/v1/courses/{cid}/quizzes/{quiz_id}/questions/{existing[n]['id']}", {"question": payload})
                self.change("update", "question", qid, existing[n]["id"])
            else:
                made = self.c.post(f"/api/v1/courses/{cid}/quizzes/{quiz_id}/questions", {"question": payload})
                self.change("create", "question", qid, made["id"])
            changed = True
        for n, extra in enumerate(existing[len(lesson.quiz.questions):], start=len(lesson.quiz.questions)):
            self.c.delete(f"/api/v1/courses/{cid}/quizzes/{quiz_id}/questions/{extra['id']}")
            self.change("delete", "question", f"{lesson.id}/q{n + 1}", extra["id"])
            changed = True
        return changed


def question_payload(q: dict, position: int) -> dict:
    payload = {
        "question_name": q.get("question_name") or f"Question {position}",
        "question_type": q["question_type"],
        "question_text": render.md_to_html(q["question_text"]),
        "points_possible": q["points_possible"],
        "position": position,
        "answers": [
            {
                "answer_html": render.md_inline(a["answer_text"]),
                "answer_text": render.md_plain(a["answer_text"]),
                "answer_weight": a["answer_weight"],
                **({"answer_comments": a["answer_comments"]} if "answer_comments" in a else {}),
            }
            for a in q["answers"]
        ],
    }
    for k in ("correct_comments", "incorrect_comments", "neutral_comments"):
        if k in q:
            payload[k] = q[k]
    return payload


def question_matches(have: dict, want: dict) -> bool:
    if have.get("question_type") != want["question_type"]:
        return False
    if have.get("question_name") != want["question_name"]:
        return False
    if not render.same_html(have.get("question_text"), want["question_text"]):
        return False
    if float(have.get("points_possible") or 0) != float(want["points_possible"]):
        return False
    for k in ("correct_comments", "incorrect_comments", "neutral_comments"):
        if (have.get(k) or "") != (want.get(k) or ""):
            return False
    answers = have.get("answers") or []
    if len(answers) != len(want["answers"]):
        return False
    for a, w in zip(answers, want["answers"]):
        if float(a.get("weight", a.get("answer_weight", 0)) or 0) != float(w["answer_weight"]):
            return False
        shown = a.get("html") or a.get("answer_html") or a.get("text") or a.get("answer_text")
        if not render.same_html(shown, w["answer_html"]):
            return False
        if (a.get("comments") or a.get("answer_comments") or "") != w.get("answer_comments", ""):
            return False
    return True
