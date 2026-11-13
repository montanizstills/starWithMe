# Example course: Browser automation with Playwright and browser-use

This folder is the course that ships with starWithMe, the way `.env.example` does (SWM-198). It is also the fixture for the student test. Real courses live in the courses repo; copy this folder to start one.

The format is SWM-204's: one folder is one Canvas course, and each numbered note is one lesson (a Canvas module), in number order.

| Path | What it is |
| --- | --- |
| `course.yml` | Course settings, quiz `defaults:` and the test student (`sis_users`). Canvas field names. |
| `NNN-slug.md` | One lesson. The file name is its id and its first heading is its title. `courses apply` renders it to a Canvas page. |
| `NNN-slug.quiz.yml` | The lesson's Classic Quiz, beside its note. Canvas field names; text is Markdown. It is also the student test's answer key (`answer_weight: 100` is correct). |
| `exercises/` | Runnable Playwright exercises against the local stack (`pytest`). |

The quiz allows unlimited attempts with no time limit, so the student test can rerun against the same Canvas.

## The test student

The login is `sis_users[0].login_id` in `course.yml`. The password is never in the repo: `courses apply` and the tests read it from `TEST_STUDENT_PASSWORD`.

## Run the exercises

```bash
cd exercises
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt && playwright install chromium
pytest                                  # Module 1 runs on any local stack
export TEST_STUDENT_PASSWORD=...        # from your local .env
pytest                                  # Module 2 also needs the course applied
```

`explore_agent.py` (Module 3) calls a language model and is never run in CI.
