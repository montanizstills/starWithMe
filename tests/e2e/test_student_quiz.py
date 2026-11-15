import re

from playwright.sync_api import Locator, Page, expect


def plain(text: str) -> str:
    """Answer text as Canvas shows it: Markdown code ticks gone, spaces collapsed."""
    return " ".join(text.replace("`", "").split())


def open_course(page: Page, title: str) -> None:
    page.goto("/courses")
    link = page.get_by_role("link", name=title, exact=True)
    expect(link, f'course "{title}" not found for the test student: was `courses apply` run?').to_have_count(1)
    link.click()


def start_attempt(page: Page, quiz_title: str) -> None:
    page.get_by_role("link", name=quiz_title, exact=True).first.click()
    take = page.get_by_role("link", name=re.compile(r"^(Take the Quiz( Again)?|Resume Quiz)$"))
    expect(take, f'no attempt left on "{quiz_title}": the quiz needs allowed_attempts: -1').to_be_visible()
    take.click()


def answer(question: Locator, spec: dict, number: int) -> None:
    # SWM-204 answer key: answer_weight 100 marks a correct answer.
    wanted = {plain(a["answer_text"]) for a in spec["answers"] if a.get("answer_weight") == 100}
    found = set()
    answers = question.locator(".answer")
    for i in range(answers.count()):
        row = answers.nth(i)
        if plain(row.locator(".answer_label").inner_text()) in wanted:
            row.locator("input.question_input").check()
            found.add(plain(row.locator(".answer_label").inner_text()))
    missing = wanted - found
    assert not missing, f"question {number}: correct answer not shown in Canvas: {missing}"


def test_student_takes_quiz_and_gets_full_marks(student_page: Page, course: dict):
    page = student_page
    for quiz in course["quizzes"]:
        open_course(page, course["title"])
        start_attempt(page, quiz["title"])

        questions = page.locator("#questions .question")
        expect(questions).to_have_count(len(quiz["questions"]))
        for n, spec in enumerate(quiz["questions"]):
            answer(questions.nth(n), spec, n + 1)

        page.get_by_role("button", name="Submit Quiz").click()

        points = f'{sum(q["points_possible"] for q in quiz["questions"]):g}'
        expect(page.locator("body"), f'"{quiz["title"]}" did not score full marks').to_contain_text(
            re.compile(rf"\b{points} out of {points}\b")
        )


def test_wrong_password_is_rejected(page: Page, base_url: str):
    # Guards the login check itself: a bad password must not reach the dashboard.
    page.goto("/login/canvas")
    form = page.locator("#login_form")
    form.get_by_label("Email").fill("student-test-wrong-login")
    form.get_by_label("Password").fill("wrong-password")
    form.get_by_role("button", name="Log In").click()
    expect(page).not_to_have_url(f"{base_url}/")
