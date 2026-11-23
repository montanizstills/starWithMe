# Module 2: Testing a Canvas login and course page

Now you'll test a real user journey: a student logs in, opens this course, and sees its modules. You'll also learn to log in once and reuse the session, so tests stay fast.

## The test student

`courses apply` creates a test student and enrolls them in this course. The student's login is in `course.yml` (`sis_users`), so it isn't secret. The password is: it comes only from the environment variable `TEST_STUDENT_PASSWORD`. Never write it into code.

```bash
export CANVAS_URL=http://localhost:3000
export TEST_STUDENT_PASSWORD=...   # from your local .env
```

The tests in `exercises/` skip with a clear message if the password isn't set.

## Logging in

```python
import os
from playwright.sync_api import Page, expect

from conftest import student_login_id  # reads course.yml

def log_in(page: Page) -> None:
    page.goto("/login/canvas")
    form = page.locator("#login_form")  # skip the hidden "Forgot Password" form
    form.get_by_label("Email").fill(student_login_id())  # Canvas labels the login field "Email"
    form.get_by_label("Password").fill(os.environ["TEST_STUDENT_PASSWORD"])
    form.get_by_role("button", name="Log In").click()
    expect(page).to_have_url(f"{os.environ.get('CANVAS_URL', 'http://localhost:3000')}/")
```

After a successful login, Canvas sends the student to the Dashboard at `/`.

## Log in once, reuse the session

Logging in for every test is slow. Save the logged-in state once and load it in each test:

```python
# conftest.py (simplified)
@pytest.fixture(scope="session")
def student_state(browser, base_url, tmp_path_factory):
    path = tmp_path_factory.mktemp("auth") / "student.json"
    context = browser.new_context(base_url=base_url)
    page = context.new_page()
    log_in(page)
    context.storage_state(path=path)
    context.close()
    return path
```

`storage_state` holds cookies, which count as credentials. Keep the file in a temporary folder and never commit it.

## Page objects

When several tests touch the same page, put its locators in one class. If Canvas changes, you fix one place.

```python
class CoursePage:
    def __init__(self, page: Page):
        self.page = page

    def open(self, course_name: str) -> None:
        self.page.goto("/courses")
        self.page.get_by_role("link", name=course_name).first.click()

    def module_titles(self):
        return self.page.locator(".context_module .ig-header-title")
```

Here `.ig-header-title` is a CSS fallback: the Canvas Modules page doesn't give each module header an accessible name.

## Exercises

1. **Run the journey test.** `pytest test_02_student_course.py`. It logs in, opens *Browser automation with Playwright and browser-use*, and checks the four module titles in order.
2. **Open the quiz.** Add a test that opens Module 4 and asserts that the quiz title is visible. Don't submit it; the automated student test does that.
3. **Check the code blocks.** Open this page in Canvas and assert that the first code block renders as preformatted code. Hint: `page.locator("pre code").first`.
4. **Break it on purpose.** Set a wrong password and confirm the login helper fails with a readable message, not a timeout 30 seconds later.

## Key points

- Credentials come from environment variables; saved sessions stay out of git.
- Log in once per test session with `storage_state`.
- Page objects keep locators in one place.
