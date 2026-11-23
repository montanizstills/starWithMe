"""courses validate <folder> | courses apply <folder> --target local|staging

stdout carries exactly one JSON object; progress and errors go to stderr.
Exit codes (SWM-205): 0 success, 1 validation error (Canvas not called),
2 configuration error (missing variable, Canvas unreachable, token refused),
3 Canvas rejected part of the apply (rerunning is safe).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from .canvas import Canvas, CanvasError, ConfigError, redact, register_secret
from .model import load_course

LOCAL_URL = "http://localhost:3000"


def read_dotenv(path: Path) -> dict:
    values = {}
    if not path.is_file():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip().removeprefix("export ").strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        values[key] = value
    return values


def settings(target: str, environ=None, dotenv_path: Path | None = None) -> dict:
    """Exported variables win; --target local also reads ./.env; staging never does."""
    env = dict(environ if environ is not None else os.environ)
    if target == "local":
        for k, v in read_dotenv(dotenv_path or Path(".env")).items():
            env.setdefault(k, v)
    url = env.get("CANVAS_URL") or (LOCAL_URL if target == "local" else "")
    if not url:
        raise ConfigError("CANVAS_URL is required for --target staging (the staging URL on the tailnet)")
    token = env.get("CANVAS_API_TOKEN", "")
    if not token:
        raise ConfigError("CANVAS_API_TOKEN is not set (tools/canvas-api-token.sh writes it to .env for local)")
    register_secret(token)
    password = env.get("TEST_STUDENT_PASSWORD") or None
    register_secret(password)
    return {"url": url, "token": token, "password": password, "account_id": env.get("CANVAS_ACCOUNT_ID") or "1"}


def emit(obj: dict) -> None:
    sys.stdout.write(json.dumps(obj, indent=2) + "\n")
    sys.stdout.flush()


def cmd_validate(args) -> int:
    course = load_course(args.folder)
    for issue in course.issues:
        print(issue, file=sys.stderr)
    quizzes = sum(1 for l in course.lessons if l.quiz)
    ok = not course.errors
    print(f"{'ok' if ok else 'invalid'}: {course.sis_id}: {len(course.lessons)} lesson(s), {quizzes} quiz(zes), "
          f"{len(course.skipped)} skipped, {len(course.errors)} error(s), {len(course.warnings)} warning(s)", file=sys.stderr)
    emit({
        "course": course.sis_id,
        "valid": ok,
        "lessons": len(course.lessons),
        "quizzes": quizzes,
        "skipped": course.skipped,
        "errors": [i.as_dict() for i in course.errors],
        "warnings": [i.as_dict() for i in course.warnings],
    })
    return 0 if ok else 1


def cmd_apply(args) -> int:
    from .apply import Applier

    course = load_course(args.folder)
    for issue in course.issues:
        print(issue, file=sys.stderr)
    if course.errors:
        print(f"invalid: {len(course.errors)} error(s); Canvas was not called. Run: courses validate {args.folder}", file=sys.stderr)
        return 1
    try:
        cfg = settings(args.target)
        if course.sis_users and not cfg["password"]:
            raise ConfigError("TEST_STUDENT_PASSWORD is not set, and course.yml lists sis_users")
        canvas = Canvas(cfg["url"], cfg["token"])
        applier = Applier(canvas, course, args.target, cfg["account_id"], cfg["password"], args.reset_password)
        print(f"applying {course.sis_id} to {args.target} ({cfg['url']})", file=sys.stderr)
        report = applier.run()
    except ConfigError as e:
        print(f"error: {redact(e)}", file=sys.stderr)
        return 2
    except CanvasError as e:
        print(f"error: {redact(e)}", file=sys.stderr)
        report = applier.report()
        report["error"] = redact(e)
        emit(report)
        return 3
    s = report["summary"]
    print(f"done: {s['created']} created, {s['updated']} updated, {s['unchanged']} unchanged, {len(report['skipped'])} skipped", file=sys.stderr)
    emit(report)
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="courses", description="Courses as code for Canvas (SWM-203).")
    sub = p.add_subparsers(dest="command", required=True)
    v = sub.add_parser("validate", help="check a course folder against the format (SWM-204)")
    v.add_argument("folder")
    v.set_defaults(func=cmd_validate)
    a = sub.add_parser("apply", help="make Canvas match a course folder (SWM-205)")
    a.add_argument("folder")
    a.add_argument("--target", choices=["local", "staging"], required=True)
    a.add_argument("--reset-password", action="store_true",
                   help="set the test students' password to TEST_STUDENT_PASSWORD again, even if they already exist")
    a.set_defaults(func=cmd_apply)
    args = p.parse_args(argv)
    try:
        return args.func(args)
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    sys.exit(main())
