"""Student test (SWM-226 in CI, SWM-225 on staging).

The test student logs in, opens the example course, takes its Classic Quiz
with the answer key from the course files and must score full marks.

  CANVAS_URL                Canvas base URL (default http://localhost:3000)
  CANVAS_STUDENT_LOGIN      the SIS test student's login_id (no email), from the course users file
  TEST_STUDENT_PASSWORD     that student's password; never printed
  COURSE_DIR                course folder (default courses/example-playwright-browser-use)
"""
import os
from pathlib import Path

import pytest
import yaml
from playwright.sync_api import Page, expect

ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture(scope="session")
def base_url():
    return os.environ.get("CANVAS_URL", "http://localhost:3000").rstrip("/")


@pytest.fixture(scope="session")
def course():
    course_dir = ROOT / os.environ.get("COURSE_DIR", "courses/example-playwright-browser-use")
    course_file = course_dir / "course.yml"
    if not course_file.is_file():
        pytest.fail(f"course file not found: {course_file}")
    data = yaml.safe_load(course_file.read_text())
    quizzes = [
        yaml.safe_load((course_dir / item["quiz"]).read_text())
        for module in data["modules"]
        for item in module.get("items", [])
        if "quiz" in item
    ]
    if not quizzes:
        pytest.fail(f"{course_file} has no quiz")
    return {"title": data["title"], "quizzes": quizzes}


def student_credentials():
    login = os.environ.get("CANVAS_STUDENT_LOGIN")
    password = os.environ.get("TEST_STUDENT_PASSWORD")
    # This is a release gate, so missing credentials fail instead of skipping.
    if not (login and password):
        pytest.fail("set CANVAS_STUDENT_LOGIN and TEST_STUDENT_PASSWORD")
    return login, password


def log_in(page: Page, base_url: str) -> None:
    login, password = student_credentials()
    page.goto("/login/canvas")
    form = page.locator("#login_form")
    # Canvas labels the login_id field "Email" even for users without one.
    form.get_by_label("Email").fill(login)
    form.get_by_label("Password").fill(password)
    form.get_by_role("button", name="Log In").click()
    expect(page, "login failed: check the test student's login and password").to_have_url(f"{base_url}/")


@pytest.fixture(scope="session")
def student_state(browser, base_url, tmp_path_factory):
    # Log in once in a context of its own, so the password is typed outside the
    # page the test records; the session file stays in a temp dir.
    path = tmp_path_factory.mktemp("auth") / "student.storage.json"
    context = browser.new_context(base_url=base_url)
    log_in(context.new_page(), base_url)
    context.storage_state(path=path)
    context.close()
    return path


@pytest.fixture
def student_page(browser, base_url, student_state):
    context = browser.new_context(base_url=base_url, storage_state=student_state)
    yield context.new_page()
    context.close()
