import os
from pathlib import Path

import pytest
import yaml
from playwright.sync_api import Page, expect

COURSE_DIR = Path(__file__).resolve().parent.parent
COURSE = yaml.safe_load((COURSE_DIR / "course.yml").read_text())
COURSE_NAME = COURSE["name"]


@pytest.fixture(scope="session")
def base_url(pytestconfig):
    return os.environ.get("CANVAS_URL") or pytestconfig.getini("base_url") or "http://localhost:3000"


def student_login_id() -> str:
    return COURSE["sis_users"][0]["login_id"]


def lesson_titles() -> list[str]:
    """Each numbered note is a lesson (a Canvas module); its first heading is the title."""
    return [
        next(line[2:].strip() for line in note.read_text().splitlines() if line.startswith("# "))
        for note in sorted(COURSE_DIR.glob("[0-9][0-9][0-9]-*.md"))
    ]


def student_credentials():
    password = os.environ.get("TEST_STUDENT_PASSWORD")
    if not password:
        pytest.skip("Set TEST_STUDENT_PASSWORD (see Module 2)")
    return student_login_id(), password


def log_in(page: Page, base_url: str) -> None:
    login_id, password = student_credentials()
    page.goto("/login/canvas")
    form = page.locator("#login_form")
    form.get_by_label("Email").fill(login_id)  # Canvas labels the login field "Email"
    form.get_by_label("Password").fill(password)
    form.get_by_role("button", name="Log In").click()
    expect(page, "login failed: check the student credentials").to_have_url(f"{base_url}/")


@pytest.fixture(scope="session")
def student_state(browser, base_url, tmp_path_factory):
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
