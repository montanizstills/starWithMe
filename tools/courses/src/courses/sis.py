"""SIS Import for the course structure: the course, its test students and their
enrollments (SWM-205). The CSV zip holds the test student password, so it is
only ever written to a private temporary folder that is deleted afterwards."""
from __future__ import annotations

import csv
import io
import sys
import tempfile
import time
import zipfile
from pathlib import Path

from .canvas import Canvas, CanvasError, ConfigError, redact

USER_FIELDS = ["user_id", "login_id", "full_name", "first_name", "last_name", "short_name", "sortable_name", "status"]
DONE_STATES = {"imported", "imported_with_messages", "failed", "failed_with_messages", "aborted", "partially_restored", "restored"}


def build_zip(courses: list, users: list, enrollments: list, password: str | None) -> bytes:
    files = {}
    if courses:
        files["courses.csv"] = (["course_id", "short_name", "long_name", "status"], courses)
    if users:
        cols = [c for c in USER_FIELDS if any(c in u for u in users)]
        for c in ("user_id", "login_id", "status"):
            if c not in cols:
                cols.append(c)
        rows = []
        for u in users:
            row = {c: u.get(c, "") for c in cols}
            row["status"] = row["status"] or "active"
            row["password"] = password or ""
            rows.append(row)
        files["users.csv"] = (cols + ["password"], rows)
    if enrollments:
        files["enrollments.csv"] = (["course_id", "user_id", "role", "status"], enrollments)

    with tempfile.TemporaryDirectory(prefix="courses-sis-") as tmp:
        zpath = Path(tmp) / "sis.zip"
        with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
            for name, (cols, rows) in files.items():
                buf = io.StringIO()
                w = csv.DictWriter(buf, fieldnames=cols, lineterminator="\n")
                w.writeheader()
                w.writerows(rows)
                z.writestr(name, buf.getvalue())
        return zpath.read_bytes()


def run_import(canvas: Canvas, account_id: str, payload: bytes, timeout: float = 900, poll: float = 3) -> dict:
    try:
        job = canvas.request(
            "POST",
            f"/api/v1/accounts/{account_id}/sis_imports",
            params={"import_type": "instructure_csv", "extension": "zip"},
            raw=payload,
            content_type="application/zip",
        )[0]
    except CanvasError as e:
        if "enabled" in str(e).lower():
            raise ConfigError(
                f"SIS imports are off for account {account_id}. A site admin turns them on once: in Canvas, Admin > "
                "account > Settings > 'Allow SIS import', or in the web container: bundle exec rails runner "
                "'Account.default.update!(allow_sis_import: true)'"
            ) from None
        raise
    job_id = job["id"]
    print(f"SIS Import {job_id} started; waiting for it (the jobs worker must be running)", file=sys.stderr)
    deadline = time.monotonic() + timeout
    while job.get("workflow_state") not in DONE_STATES:
        if time.monotonic() > deadline:
            raise CanvasError(f"SIS Import {job_id} did not finish within {int(timeout)}s (state {job.get('workflow_state')}): is the jobs worker running?")
        time.sleep(poll)
        job = canvas.get(f"/api/v1/accounts/{account_id}/sis_imports/{job_id}")
    for w in job.get("processing_warnings") or []:
        print(f"SIS Import warning: {redact(' '.join(map(str, w)))}", file=sys.stderr)
    errors = job.get("processing_errors") or []
    if job["workflow_state"] not in ("imported", "imported_with_messages") or errors:
        detail = "; ".join(redact(" ".join(map(str, e))) for e in errors)[:800]
        raise CanvasError(f"SIS Import {job_id} ended as {job['workflow_state']}{': ' + detail if detail else ''}")
    return job
