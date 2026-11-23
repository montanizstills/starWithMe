import json
import textwrap

import pytest

from conftest import EXAMPLE, MINI
from courses.cli import main
from courses.model import load_course


def run(capsys, *argv):
    code = main(list(argv))
    out, err = capsys.readouterr()
    return code, json.loads(out), err


def test_mini_course_is_valid(capsys):
    code, report, err = run(capsys, "validate", str(MINI))
    assert code == 0, err
    assert report["valid"] and report["lessons"] == 3 and report["quizzes"] == 1
    assert report["skipped"] == [{"file": "003-draft.quiz.yml", "reason": "reviewed: false"}]


def test_lessons_come_from_numbered_notes():
    course = load_course(MINI)
    assert course.sis_id == "mini-course"
    assert [l.id for l in course.lessons] == ["001-introduction", "002-code", "003-draft"]
    assert [l.title for l in course.lessons] == ["Lesson 1: Introduction", "Lesson 2: Code", "Lesson 3: Draft quiz"]
    assert course.lessons[1].front_matter == {"video": {"generate": True}}
    assert "Lesson 2" not in course.lessons[1].body  # the heading became the title
    quiz = course.lessons[1].quiz
    assert quiz.settings["allowed_attempts"] == -1 and quiz.settings["time_limit"] is None  # from defaults.quiz


@pytest.mark.skipif(not EXAMPLE.is_dir(), reason="example course (SWM-198) not on this branch")
def test_example_course_is_valid(capsys):
    code, report, err = run(capsys, "validate", str(EXAMPLE))
    assert code == 0, err
    assert report["lessons"] == 4 and report["quizzes"] == 1


def test_200_notes(tmp_path, capsys):
    folder = tmp_path / "big-course"
    folder.mkdir()
    for n in range(1, 201):
        (folder / f"{n:03d}-topic-{n}.md").write_text(f"# Topic {n}\n\nText {n}.\n")
        (folder / f"{n:03d}-topic-{n}.quiz.yml").write_text(textwrap.dedent(f"""\
            reviewed: {"true" if n % 2 else "false"}
            title: Topic {n} check
            questions:
              - question_type: true_false_question
                points_possible: 1
                question_text: Topic {n} is a topic.
                answers:
                  - {{answer_text: "True", answer_weight: 100}}
                  - {{answer_text: "False", answer_weight: 0}}
            """))
    code, report, err = run(capsys, "validate", str(folder))
    assert code == 0, err
    assert report["lessons"] == 200 and report["quizzes"] == 100 and len(report["skipped"]) == 100


def test_broken_copy_fails_clearly(mini, capsys):
    (mini / "002-again.md").write_text("# Again\n")
    (mini / "005-gap.md").write_text("# Gap\n")
    (mini / "notes.md").write_text("# Scratch\n")
    (mini / "001-no-heading.md").unlink(missing_ok=True)
    (mini / "007-orphan.quiz.yml").write_text("reviewed: true\ntitle: x\nquestions: []\n")
    quiz = (mini / "002-code.quiz.yml").read_text()
    quiz = quiz.replace("answer_weight: 0\n  - question_type: true_false", "answer_weight: 100\n  - question_type: true_false", 1)
    quiz = quiz.replace("points_possible: 2", "points_possible: 2\n    question_typo: yes")
    (mini / "002-code.quiz.yml").write_text(quiz)
    course_yml = (mini / "course.yml").read_text().replace("status: active", "status: active\n    password: hunter2")
    (mini / "course.yml").write_text(course_yml)

    code, report, err = run(capsys, "validate", str(mini))
    assert code == 1
    messages = [": ".join(x for x in (e["file"], e["path"], e["message"]) if x) for e in report["errors"]]
    warnings = [f"{w['file']}: {w['message']}" for w in report["warnings"]]
    assert any(m.startswith("002-code.md: duplicate number 002: also used by 002-again.md") for m in messages), messages
    assert any(m.startswith("002-code.quiz.yml: questions[0].answers:") and "exactly one" in m for m in messages), messages
    assert any(m.startswith("002-code.quiz.yml: questions[2].question_typo:") for m in messages), messages
    assert any(m.startswith("course.yml: sis_users[0].password:") and "TEST_STUDENT_PASSWORD" in m for m in messages), messages
    assert any(m.startswith("007-orphan.quiz.yml") for m in messages), messages
    assert any("missing lesson number(s): 004" in w for w in warnings), warnings
    assert any(w.startswith("notes.md: no number prefix") for w in warnings), warnings
    assert "hunter2" not in err + json.dumps(report)


@pytest.mark.parametrize("name,text,expect", [
    ("010-x.md", "No heading here.\n", "no heading"),
    ("01-short.md", "# Short\n", "3 digits"),
    ("011-Bad_Name.md", "# Bad\n", "lowercase"),
])
def test_note_name_and_heading_errors(mini, capsys, name, text, expect):
    (mini / name).write_text(text)
    code, report, _ = run(capsys, "validate", str(mini))
    assert code == 1
    assert any(e["file"] == name and expect in e["message"] for e in report["errors"]), report["errors"]


def test_video_front_matter_rejects_generated_fields(mini, capsys):
    (mini / "004-video.md").write_text("---\nvideo:\n  generate: true\n  url: https://x\n---\n# Video\n")
    code, report, _ = run(capsys, "validate", str(mini))
    assert code == 1
    assert {"file": "004-video.md", "path": "video.url", "message": "unknown field (not a supported Canvas field)"} in report["errors"]


def test_heading_inside_code_fence_is_not_the_title(tmp_path):
    folder = tmp_path / "c"
    folder.mkdir()
    (folder / "001-a.md").write_text("```bash\n# comment\n```\n\n# Real title\n")
    assert load_course(folder).lessons[0].title == "Real title"
