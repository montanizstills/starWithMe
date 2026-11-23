"""Load a course folder and check it against the SWM-204 format.

One folder = one Canvas course. Each numbered note (NNN-slug.md) is one lesson,
in number order: its file name is its id and its first heading is its title.
A lesson's Classic Quiz sits beside it as NNN-slug.quiz.yml. course.yml is
optional and holds course settings, quiz defaults and the test students.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from importlib import resources
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft202012Validator

NOTE_RE = re.compile(r"^(?P<num>\d+)-(?P<slug>.+)\.md$")
QUIZ_RE = re.compile(r"^(?P<num>\d+)-(?P<slug>.+)\.quiz\.yml$")
SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FOLDER_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
HEADING_RE = re.compile(r"^#{1,6}\s+(?P<title>.+?)\s*#*\s*$")
FENCE_RE = re.compile(r"^\s*(```|~~~)")
NUMBER_WIDTH = 3

# Files a course folder may hold that are not lessons and need no warning.
QUIET_FILES = {"course.yml", "README.md", "media.lock.yml", ".gitignore"}


@dataclass
class Issue:
    level: str  # "error" or "warning"
    file: str
    path: str
    message: str

    def __str__(self) -> str:
        where = f"{self.file}: {self.path}" if self.path else self.file
        return f"{self.level}: {where}: {self.message}"

    def as_dict(self) -> dict:
        return {"file": self.file, "path": self.path, "message": self.message}


@dataclass
class Quiz:
    file: str
    reviewed: bool
    title: str
    description: str
    settings: dict  # course defaults.quiz overlaid with the quiz file's own settings
    questions: list


@dataclass
class Lesson:
    id: str
    number: int
    file: str
    title: str
    body: str  # the note's Markdown without its front matter and first heading
    front_matter: dict
    quiz: Quiz | None = None


@dataclass
class Course:
    folder: Path
    sis_id: str
    name: str
    course_code: str | None
    settings: dict  # course.yml fields that map onto the Canvas course object
    sis_users: list
    lessons: list = field(default_factory=list)
    skipped: list = field(default_factory=list)  # [{"file", "reason"}]
    issues: list = field(default_factory=list)

    @property
    def errors(self) -> list:
        return [i for i in self.issues if i.level == "error"]

    @property
    def warnings(self) -> list:
        return [i for i in self.issues if i.level == "warning"]


def _load_schema() -> dict:
    text = resources.files("courses").joinpath("schema/course-format.schema.json").read_text()
    return json.loads(text)


_SCHEMA = _load_schema()


def _validator(definition: str) -> Draft202012Validator:
    schema = {"$schema": _SCHEMA["$schema"], "$defs": _SCHEMA["$defs"], "$ref": f"#/$defs/{definition}"}
    return Draft202012Validator(schema)


VALIDATORS = {name: _validator(name) for name in ("course", "quiz", "note_front_matter")}


def format_path(parts) -> str:
    """questions, 2, answers -> questions[2].answers"""
    out = ""
    for p in parts:
        if isinstance(p, int):
            out += f"[{p}]"
        else:
            out += f".{p}" if out else str(p)
    return out


def _schema_issues(definition: str, data: Any, file: str) -> list:
    issues = []
    for err in sorted(VALIDATORS[definition].iter_errors(data), key=lambda e: list(e.absolute_path)):
        path = list(err.absolute_path)
        msg = err.message
        if err.validator == "additionalProperties":
            extra = sorted(set(err.instance) - set(err.schema.get("properties", {})))
            for key in extra:
                hint = "not a supported Canvas field"
                if key == "password":
                    hint = "passwords never go in course files; courses apply reads TEST_STUDENT_PASSWORD"
                elif key == "email":
                    hint = "test students have no email"
                issues.append(Issue("error", file, format_path(path + [key]), f"unknown field ({hint})"))
            continue
        if err.validator == "required":
            missing = re.search(r"'([^']+)' is a required property", msg)
            if missing:
                issues.append(Issue("error", file, format_path(path + [missing.group(1)]), "required field is missing"))
                continue
        issues.append(Issue("error", file, format_path(path), msg))
    return issues


def _read_yaml(path: Path, rel: str, issues: list) -> Any:
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as e:
        mark = getattr(e, "problem_mark", None)
        where = f"line {mark.line + 1}" if mark else ""
        issues.append(Issue("error", rel, where, f"not valid YAML: {getattr(e, 'problem', e)}"))
    except UnicodeDecodeError:
        issues.append(Issue("error", rel, "", "not UTF-8 text"))
    return None


def split_note(text: str) -> tuple:
    """Returns (front_matter_text or None, title or None, body without the first heading)."""
    front = None
    if text.startswith("---\n") or text.startswith("---\r\n"):
        lines = text.splitlines(keepends=True)
        for i in range(1, len(lines)):
            if lines[i].rstrip() == "---":
                front = "".join(lines[1:i])
                text = "".join(lines[i + 1:])
                break
    title = None
    out = []
    in_fence = False
    for line in text.splitlines(keepends=True):
        if FENCE_RE.match(line):
            in_fence = not in_fence
        if title is None and not in_fence:
            m = HEADING_RE.match(line.rstrip("\r\n"))
            if m:
                title = m.group("title")
                continue
        out.append(line)
    return front, title, "".join(out).strip("\n") + "\n"


def _check_question(q: dict, path: str, rel: str, issues: list) -> None:
    answers = q.get("answers") or []
    if not isinstance(answers, list):
        return
    correct = [a for a in answers if isinstance(a, dict) and a.get("answer_weight") == 100]
    qtype = q.get("question_type")
    if qtype == "multiple_choice_question" and len(correct) != 1:
        issues.append(Issue("error", rel, f"{path}.answers", f"multiple_choice_question needs exactly one answer with answer_weight: 100 (found {len(correct)})"))
    elif qtype == "multiple_answers_question" and not correct:
        issues.append(Issue("error", rel, f"{path}.answers", "multiple_answers_question needs at least one answer with answer_weight: 100"))
    elif qtype == "true_false_question":
        texts = sorted(str(a.get("answer_text")) for a in answers if isinstance(a, dict))
        if texts != ["False", "True"]:
            issues.append(Issue("error", rel, f"{path}.answers", 'true_false_question needs exactly two answers, "True" and "False"'))
        elif len(correct) != 1:
            issues.append(Issue("error", rel, f"{path}.answers", "true_false_question needs exactly one answer with answer_weight: 100"))
    seen = set()
    for i, a in enumerate(answers):
        if isinstance(a, dict) and a.get("answer_text") in seen:
            issues.append(Issue("error", rel, f"{path}.answers[{i}].answer_text", "duplicate answer text"))
        if isinstance(a, dict):
            seen.add(a.get("answer_text"))


def load_course(folder) -> Course:
    folder = Path(folder)
    issues: list = []
    sis_id = folder.resolve().name
    course = Course(folder=folder, sis_id=sis_id, name=sis_id, course_code=None, settings={}, sis_users=[], issues=issues)

    if not folder.is_dir():
        issues.append(Issue("error", str(folder), "", "not a folder"))
        return course
    if not FOLDER_RE.match(sis_id):
        issues.append(Issue("error", sis_id, "", "the folder name is the course's SIS id: use letters, digits, '.', '_' or '-'"))

    # course.yml (optional)
    defaults_quiz: dict = {}
    course_file = folder / "course.yml"
    if course_file.is_file():
        data = _read_yaml(course_file, "course.yml", issues)
        if data is None:
            data = {}
        if not isinstance(data, dict):
            issues.append(Issue("error", "course.yml", "", "must be a mapping of course fields"))
            data = {}
        issues.extend(_schema_issues("course", data, "course.yml"))
        course.name = data.get("name") or sis_id
        course.course_code = data.get("course_code")
        course.settings = {k: data[k] for k in ("name", "course_code", "default_view", "public_description") if k in data}
        course.settings.setdefault("name", course.name)
        defaults_quiz = dict((data.get("defaults") or {}).get("quiz") or {})
        users = data.get("sis_users") or []
        course.sis_users = users if isinstance(users, list) else []
        seen_users: dict = {}
        for i, u in enumerate(course.sis_users):
            if not isinstance(u, dict):
                continue
            for key in ("user_id", "login_id"):
                v = u.get(key)
                if v in seen_users.setdefault(key, set()):
                    issues.append(Issue("error", "course.yml", f"sis_users[{i}].{key}", f"duplicate {key} {v!r}"))
                seen_users[key].add(v)
    else:
        course.settings = {"name": course.name}

    # Notes and quizzes
    notes: dict = {}  # number -> [filenames]
    quiz_files: dict = {}  # note id -> filename
    for path in sorted(folder.iterdir()):
        name = path.name
        if path.is_dir() or name.startswith("."):
            continue
        m = QUIZ_RE.match(name)
        if m:
            quiz_files[name[: -len(".quiz.yml")]] = name
            continue
        m = NOTE_RE.match(name)
        if m:
            if len(m.group("num")) != NUMBER_WIDTH:
                issues.append(Issue("error", name, "", f"the number prefix must be {NUMBER_WIDTH} digits, like 001-"))
                continue
            if not SLUG_RE.match(m.group("slug")):
                issues.append(Issue("error", name, "", "after the number, use lowercase letters, digits and single hyphens (001-my-topic.md)"))
                continue
            notes.setdefault(int(m.group("num")), []).append(name)
            continue
        if name.endswith(".md") and name not in QUIET_FILES:
            issues.append(Issue("warning", name, "", "no number prefix (NNN-slug.md), so it is not a lesson and is not included"))
        elif name.endswith(".quiz.yml"):
            issues.append(Issue("error", name, "", "quiz file name must be NNN-slug.quiz.yml, beside its note"))

    for num, names in sorted(notes.items()):
        if len(names) > 1:
            issues.append(Issue("error", names[1], "", f"duplicate number {num:0{NUMBER_WIDTH}d}: also used by {', '.join(n for n in names if n != names[1])}"))
    numbers = sorted(notes)
    if numbers:
        missing = sorted(set(range(numbers[0], numbers[-1] + 1)) - set(numbers))
        if numbers[0] != 1:
            missing = list(range(1, numbers[0])) + missing
        if missing:
            shown = ", ".join(f"{n:0{NUMBER_WIDTH}d}" for n in missing[:10]) + (" ..." if len(missing) > 10 else "")
            issues.append(Issue("warning", str(folder.name), "", f"missing lesson number(s): {shown}"))
    else:
        issues.append(Issue("error", str(folder.name), "", "no lessons: add numbered notes like 001-introduction.md"))

    note_ids = set()
    for num, name in [(n, name) for n in numbers for name in notes[n]]:
        note_id = name[:-3]
        note_ids.add(note_id)
        text = (folder / name).read_text(encoding="utf-8")
        front_text, title, body = split_note(text)
        front = {}
        if front_text is not None:
            try:
                front = yaml.safe_load(front_text) or {}
            except yaml.YAMLError as e:
                issues.append(Issue("error", name, "front matter", f"not valid YAML: {getattr(e, 'problem', e)}"))
                front = {}
            if not isinstance(front, dict):
                issues.append(Issue("error", name, "front matter", "must be a mapping"))
                front = {}
            issues.extend(_schema_issues("note_front_matter", front, name))
        if not title:
            issues.append(Issue("error", name, "", "no heading: the note's first heading is the lesson title"))
            title = note_id
        lesson = Lesson(id=note_id, number=num, file=name, title=title, body=body, front_matter=front)
        if note_id in quiz_files:
            lesson.quiz = _load_quiz(folder / quiz_files[note_id], quiz_files[note_id], defaults_quiz, issues)
            if lesson.quiz and not lesson.quiz.reviewed:
                course.skipped.append({"file": quiz_files[note_id], "reason": "reviewed: false"})
                issues.append(Issue("warning", quiz_files[note_id], "reviewed", "reviewed: false, so courses apply skips this quiz"))
                lesson.quiz = None
        course.lessons.append(lesson)

    for note_id, qname in sorted(quiz_files.items()):
        if note_id not in note_ids:
            issues.append(Issue("error", qname, "", f"no note {note_id}.md beside this quiz"))
            _load_quiz(folder / qname, qname, defaults_quiz, issues)

    titles: dict = {}
    for lesson in course.lessons:
        if lesson.quiz:
            if lesson.quiz.title in titles:
                issues.append(Issue("error", lesson.quiz.file, "title", f"duplicate quiz title, also in {titles[lesson.quiz.title]} (quizzes are matched by title)"))
            titles[lesson.quiz.title] = lesson.quiz.file
    return course


def _load_quiz(path: Path, rel: str, defaults: dict, issues: list):
    data = _read_yaml(path, rel, issues)
    if data is None:
        return None
    if not isinstance(data, dict):
        issues.append(Issue("error", rel, "", "must be a mapping of quiz fields"))
        return None
    before = len(issues)
    issues.extend(_schema_issues("quiz", data, rel))
    for i, q in enumerate(data.get("questions") or []):
        if isinstance(q, dict):
            _check_question(q, f"questions[{i}]", rel, issues)
    if len(issues) > before and any(i.level == "error" for i in issues[before:]):
        return None
    settings = dict(defaults)
    for key in VALIDATORS["quiz"].schema["$defs"]["quiz_settings"]["properties"]:
        if key in data:
            settings[key] = data[key]
    return Quiz(
        file=rel,
        reviewed=data["reviewed"],
        title=data["title"],
        description=data.get("description", ""),
        settings=settings,
        questions=data["questions"],
    )
