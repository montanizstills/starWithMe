from playwright.sync_api import Page, expect


def test_login_page_loads(page: Page):
    page.goto("/login/canvas")
    expect(page).to_have_title("Canvas Login | Instructure")


def test_login_page_has_form(page: Page):
    page.goto("/login/canvas")
    # The page also holds a hidden "forgot password" form with its own Email field.
    form = page.locator("#login_form")
    expect(form.get_by_label("Email")).to_be_visible()
    expect(form.get_by_label("Password")).to_be_visible()
    expect(form.get_by_role("button", name="Log In")).to_be_enabled()


# Exercise 2: write test_wrong_password_shows_error here.
