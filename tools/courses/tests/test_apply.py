import json

import pytest

from conftest import MINI
from courses import cli, sis
from fake_canvas import FakeCanvas

PASSWORD = "student-pass-9f8e7d"


@pytest.fixture(autouse=True)
def fast_sis(monkeypatch):
    monkeypatch.setattr(sis.time, "sleep", lambda s: None)


@pytest.fixture
def canvas(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)  # no stray ./.env
    with FakeCanvas() as fake:
        monkeypatch.setenv("CANVAS_URL", fake.url)
        monkeypatch.setenv("CANVAS_API_TOKEN", fake.state.token)
        monkeypatch.setenv("TEST_STUDENT_PASSWORD", PASSWORD)
        yield fake


def apply(capsys, folder=MINI, *extra):
    code = cli.main(["apply", str(folder), "--target", "staging", *extra])
    out, err = capsys.readouterr()
    return code, (json.loads(out) if out.strip() else None), err


def kinds(report):
    return sorted((c["action"], c["type"]) for c in report["changes"])


def test_first_apply_creates_everything_and_second_changes_nothing(canvas, capsys):
    code, first, err = apply(capsys)
    assert code == 0, err
    st = canvas.state
    assert kinds(first) == sorted(
        [("create", "course"), ("create", "user"), ("create", "enrollment")]
        + [("create", "module")] * 3 + [("create", "page")] * 3
        + [("create", "quiz")] + [("create", "question")] * 3
    )
    assert first["skipped"] == [{"file": "003-draft.quiz.yml", "reason": "reviewed: false"}]
    course = st.courses[first["course_id"]]
    assert course["sis_course_id"] == "mini-course" and course["workflow_state"] == "available"
    assert course["public_description"] == "A tiny course for the courses tool tests."
    assert st.passwords == {"mini-101-student": PASSWORD}
    assert st.enrollments[0]["enrollment_state"] == "active"

    mods = sorted(st.modules[first["course_id"]], key=lambda m: m["position"])
    assert [m["name"] for m in mods] == ["Lesson 1: Introduction", "Lesson 2: Code", "Lesson 3: Draft quiz"]
    assert all(m["published"] for m in mods)
    assert [i["type"] for i in st.items[mods[1]["id"]]] == ["Page", "Quiz"]
    assert [i["type"] for i in st.items[mods[2]["id"]]] == ["Page"]  # draft quiz skipped

    page = st.pages[first["course_id"]]["lesson-2-code"]
    assert '<pre><code class="language-python">' in page["body"] and page["published"]

    quiz = st.quizzes[first["course_id"]][0]
    assert quiz["published"] and quiz["allowed_attempts"] == -1 and quiz["time_limit"] is None
    assert first["quizzes"] == [{"id": "002-code", "title": "Lesson 2 check", "canvas_id": quiz["id"]}]
    qs = st.questions[quiz["id"]]
    assert [q["question_type"] for q in qs] == ["multiple_choice_question", "true_false_question", "multiple_answers_question"]
    assert "<pre><code" in qs[0]["question_text"]
    assert qs[0]["answers"][0]["html"] == "<code>\"Hello, Ada &amp; &lt;friends&gt;\"</code>".replace("\"", "&#34;") or "<code>" in qs[0]["answers"][0]["html"]
    assert [a["weight"] for a in qs[2]["answers"]] == [100, 100, 0]

    # Questions are created before the quiz is published.
    reqs = st.requests
    publish = max(i for i, r in enumerate(reqs) if r[0] == "PUT" and r[1].endswith(f"/quizzes/{quiz['id']}"))
    last_q = max(i for i, r in enumerate(reqs) if r[0] == "POST" and r[1].endswith("/questions"))
    assert last_q < publish

    code, second, err = apply(capsys)
    assert code == 0, err
    assert second["changes"] == [], second["changes"]
    assert second["summary"]["created"] == 0 and second["summary"]["unchanged"] > 0
    assert second["course_id"] == first["course_id"]
    assert second["quizzes"] == first["quizzes"]
    assert len(st.sis_payloads) == 1  # no SIS Import when nothing is missing


def test_edits_are_updated_in_place(canvas, capsys, mini):
    assert apply(capsys, mini)[0] == 0
    (mini / "001-introduction.md").write_text("# Lesson 1: Welcome\n\nNew text.\n")
    quiz = (mini / "002-code.quiz.yml").read_text().replace("Which are lists?", "Which are Python lists?")
    (mini / "002-code.quiz.yml").write_text(quiz)
    code, report, err = apply(capsys, mini)
    assert code == 0, err
    assert kinds(report) == [("update", "module"), ("update", "page"), ("update", "question")]
    assert {c["id"] for c in report["changes"]} == {"001-introduction", "002-code/q3"}
    assert apply(capsys, mini)[1]["changes"] == []


def test_removed_question_is_deleted(canvas, capsys, mini):
    assert apply(capsys, mini)[0] == 0
    text = (mini / "002-code.quiz.yml").read_text()
    (mini / "002-code.quiz.yml").write_text(text[: text.index("  - question_type: multiple_answers_question")])
    code, report, _ = apply(capsys, mini)
    assert code == 0
    assert kinds(report) == [("delete", "question")]


def test_reset_password_updates_the_user(canvas, capsys, monkeypatch):
    assert apply(capsys)[0] == 0
    monkeypatch.setenv("TEST_STUDENT_PASSWORD", "rotated-pass-1234")
    code, report, _ = apply(capsys, MINI, "--reset-password")
    assert code == 0
    assert kinds(report) == [("update", "user")]
    assert canvas.state.passwords["mini-101-student"] == "rotated-pass-1234"


def test_secrets_never_printed(canvas, capsys):
    code, report, err = apply(capsys)
    out = json.dumps(report) + err
    assert PASSWORD not in out and canvas.state.token not in out


def test_bad_token_is_exit_2(canvas, capsys, monkeypatch):
    monkeypatch.setenv("CANVAS_API_TOKEN", "wrong-token")
    code, report, err = apply(capsys)
    assert code == 2 and report is None
    assert "refused the token" in err and "wrong-token" not in err


def test_missing_password_is_exit_2(canvas, capsys, monkeypatch):
    monkeypatch.delenv("TEST_STUDENT_PASSWORD")
    code, _, err = apply(capsys)
    assert code == 2 and "TEST_STUDENT_PASSWORD" in err
    assert canvas.state.requests == []


def test_unreachable_canvas_is_exit_2(capsys, monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("CANVAS_URL", "http://127.0.0.1:9")
    monkeypatch.setenv("CANVAS_API_TOKEN", "t")
    monkeypatch.setenv("TEST_STUDENT_PASSWORD", PASSWORD)
    monkeypatch.setattr("courses.canvas.time.sleep", lambda s: None)
    code, _, err = apply(capsys)
    assert code == 2 and "unreachable" in err


def test_staging_needs_canvas_url(capsys, monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("CANVAS_URL", raising=False)
    monkeypatch.setenv("CANVAS_API_TOKEN", "t")
    code, _, err = apply(capsys)
    assert code == 2 and "CANVAS_URL" in err


def test_invalid_course_is_exit_1_without_calling_canvas(canvas, capsys, mini):
    (mini / "002-code.quiz.yml").write_text("reviewed: true\ntitle: x\n")
    code, report, err = apply(capsys, mini)
    assert code == 1 and report is None
    assert canvas.state.requests == []


def test_local_reads_dotenv_but_exported_wins(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    (tmp_path / ".env").write_text("CANVAS_API_TOKEN=from-file\nTEST_STUDENT_PASSWORD='quoted pw'\nCANVAS_URL=http://x\n")
    cfg = cli.settings("local", environ={"CANVAS_URL": "http://exported"})
    assert cfg["token"] == "from-file" and cfg["password"] == "quoted pw" and cfg["url"] == "http://exported"
    assert cli.settings("local", environ={"CANVAS_API_TOKEN": "t"}, dotenv_path=tmp_path / "none")["url"] == "http://localhost:3000"
    with pytest.raises(cli.ConfigError):
        cli.settings("staging", environ={"CANVAS_URL": "http://s"})  # staging never reads .env


def test_canvas_error_is_exit_3_with_partial_report(canvas, capsys, monkeypatch):
    from fake_canvas import Handler
    original = Handler.route

    def failing(self, method, path, q, body):
        if method == "POST" and path.endswith("/quizzes"):
            return self._send(400, {"errors": {"title": [{"message": "is invalid"}]}})
        return original(self, method, path, q, body)

    monkeypatch.setattr(Handler, "route", failing)
    code, report, err = apply(capsys)
    assert code == 3
    assert "HTTP 400" in report["error"] and report["changes"]


def test_sis_imports_turned_off_is_exit_2_with_the_fix(canvas, capsys, monkeypatch):
    from fake_canvas import Handler
    original = Handler.route

    def off(self, method, path, q, body):
        if method == "POST" and path.endswith("/sis_imports"):
            return self._send(400, {"errors": [{"message": "SIS imports can only be executed on enabled accounts"}]})
        return original(self, method, path, q, body)

    monkeypatch.setattr(Handler, "route", off)
    code, report, err = apply(capsys)
    assert code == 2 and report is None
    assert "allow_sis_import" in err
