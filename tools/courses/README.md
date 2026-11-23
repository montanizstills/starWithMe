# courses: courses as code for Canvas

`courses validate` checks a course folder against the format ([SWM-204](https://star-with-me.atlassian.net/browse/SWM-204)). `courses apply` makes Canvas match it ([SWM-205](https://star-with-me.atlassian.net/browse/SWM-205)). The interface is fixed in [SWM-205's comment](https://star-with-me.atlassian.net/browse/SWM-205?focusedCommentId=10156).

```bash
tools/courses/courses validate courses/example-playwright-browser-use
tools/courses/courses apply courses/example-playwright-browser-use --target local > apply-report.json
```

Run from the repo root. The wrapper creates `tools/courses/.venv` on first use (Python 3.11+).

## Course folder

One folder is one Canvas course; the folder name is its SIS id.

| File | What it is |
| --- | --- |
| `NNN-slug.md` | One lesson (a module with its page), in number order. The file name is its id; the first heading is its title and is left out of the page body. Optional front matter: `video: {generate: true}`. |
| `NNN-slug.quiz.yml` | The lesson's Classic Quiz. Canvas field names. `reviewed: false` quizzes are skipped. |
| `course.yml` | Optional. `name`, `course_code`, `default_view`, `public_description`, `defaults.quiz` and `sis_users` (test students, enrolled as active students). |

The full allow-list is [`src/courses/schema/course-format.schema.json`](src/courses/schema/course-format.schema.json). Unknown fields are errors. Text is Markdown; fenced code becomes `<pre><code>`.

## Environment

| Variable | |
| --- | --- |
| `CANVAS_URL` | Default `http://localhost:3000` for `local`; required for `staging`. |
| `CANVAS_API_TOKEN` | Site admin token. Locally, `tools/apply-example-course.sh` (run by `./start.sh --local`) writes it to `.env` with `tools/canvas-token.rb` (SWM-206). |
| `TEST_STUDENT_PASSWORD` | Required when `course.yml` lists `sis_users`. |
| `CANVAS_ACCOUNT_ID` | Optional, default `1`: the root account that receives the SIS Import. |

`--target local` also reads `./.env`; exported variables win. `--target staging` never reads `.env`. The token and password are never printed. The SIS CSV zip is built in a temporary folder that is deleted.

SIS imports must be allowed on the root account once. If they are off, apply exits 2 and says how to turn them on.

## What apply does

1. **Structure, by SIS Import, only for what is missing:** the course (default term and section), the `sis_users` and their active student enrollments. It waits for the import, so the jobs worker must be running.
2. **Course settings** by the API, and publishes the course (`event: offer`).
3. **Content**, for each lesson in order: the module at that position (renamed if the title changed), its page, and its quiz. Quiz questions go in first, then the quiz is published. A published quiz is published again after its questions change.

Re-runs match the course by SIS id, a module by position, and the page and quiz through that module's items (a quiz also by title). Only what differs is sent, so a second apply with no file changes reports `"changes": []`. HTML is compared by tags and text, since Canvas rewrites attributes and whitespace when it saves.

Nothing is deleted except quiz questions past the end of a quiz file. Extra modules are left alone and noted on stderr.

An existing test student's password isn't checked (Canvas can't tell us). After rotating `TEST_STUDENT_PASSWORD`, run apply once with `--reset-password`.

## Output and exit codes

stdout is one JSON object: `course`, `target`, `course_id`, `changes` (`action` is `create`, `update` or `delete`), `skipped`, `quizzes` (each quiz's `canvas_id`, also when nothing changed) and `summary`. On exit 3 it also has `error`. Progress goes to stderr.

| Exit | Meaning |
| --- | --- |
| 0 | Success, whether or not anything changed |
| 1 | Validation error; Canvas wasn't called |
| 2 | Configuration: missing variable, Canvas unreachable, token refused, SIS imports off |
| 3 | Canvas rejected part of the apply; rerunning is safe |

## Tests

```bash
tools/courses/.venv/bin/pip install -r tools/courses/requirements-dev.txt
tools/courses/.venv/bin/python -m pytest -q tools/courses/tests
```

The unit tests run `apply` against an in-memory fake Canvas (`tests/fake_canvas.py`). CI runs them in the `courses-tool` workflow. `deploy-test` applies a course twice against the real Canvas and runs `tests/live_check.py`.
