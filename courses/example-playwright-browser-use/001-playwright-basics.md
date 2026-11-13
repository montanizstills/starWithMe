# Module 1: Playwright basics

By the end of this module you can install Playwright for Python, open a page, find elements the way a user would, and assert on what you see. Every exercise runs against **your local Canvas** at `http://localhost:3000`.

## What Playwright is

Playwright drives real browsers (Chromium, Firefox and WebKit) from code. For testing, three features matter most:

- **Auto-waiting.** Actions such as `click()` wait until the element is visible, enabled and stable, so you rarely need `sleep()`.
- **Web-first assertions.** `expect(locator).to_have_text(...)` retries until it passes or times out.
- **Isolation.** Each test gets a fresh browser context, like a new incognito window.

## Set up

You need Python 3.11 or newer.

```bash
cd courses/example-playwright-browser-use/exercises
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
playwright install chromium
```

Start the local stack from the repository root if it isn't running (`./start.sh --local`), then check it:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/login/canvas
```

You should see `200`.

## Your first script

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)
    page = browser.new_page()
    page.goto("http://localhost:3000/login/canvas")
    print(page.title())
    browser.close()
```

`headless=False` shows the browser so you can watch. Tests run headless by default.

## Locators: find elements the way a user does

Prefer locators that match what a user sees over CSS classes, which change when the design does.

| Prefer | Example on the Canvas login page |
| --- | --- |
| By label | `page.get_by_label("Email")` |
| By role and name | `page.get_by_role("button", name="Log In")` |
| By text | `page.get_by_text("Forgot Password?")` |
| By test id or CSS (last resort) | `page.locator("#pseudonym_session_unique_id")` |

### Scope your locators

The Canvas login page has a catch: it also holds a hidden "Forgot Password" form, and that form has its own field labelled **Email**. `page.get_by_label("Email")` matches both, so Playwright refuses to guess. Narrow the search to the form you mean:

```python
form = page.locator("#login_form")
form.get_by_label("Email").fill("student@example.com")
```

Chaining one locator from another (`form.get_by_label(...)`) is the standard fix whenever a page repeats a label.

To discover locators, let Playwright record you:

```bash
playwright codegen http://localhost:3000/login/canvas
```

Click around and copy the code it writes.

## Assertions

```python
from playwright.sync_api import Page, expect

def test_login_page_has_form(page: Page):
    page.goto("/login/canvas")
    form = page.locator("#login_form")
    expect(form.get_by_label("Email")).to_be_visible()
    expect(form.get_by_label("Password")).to_be_visible()
    expect(form.get_by_role("button", name="Log In")).to_be_enabled()
```

`page` comes from the `pytest-playwright` plugin. The `/login/canvas` path is relative because `pytest.ini` sets the base URL.

## Exercises

All exercise files are in `exercises/`. Run them with `pytest`.

1. **Run the provided test.** `pytest test_01_login_page.py`. All tests should pass.
2. **Add a negative test.** Write `test_wrong_password_shows_error`. Fill in any email and a wrong password, click **Log In**, and assert that an error message is visible. Use `codegen` to find the message's text.
3. **Watch it run.** Rerun with `pytest --headed --slowmo 500` and watch each step.
4. **Read a trace.** Run `pytest --tracing retain-on-failure`, break one assertion on purpose, then open the trace with `playwright show-trace test-results/<test>/trace.zip`.

## Key points

- Use labels, roles and text before CSS.
- Let auto-waiting and `expect()` handle timing; never add `sleep()`.
- `codegen` and the trace viewer are your two best debugging tools.
