from playwright.sync_api import Page, expect

from conftest import COURSE_NAME, lesson_titles


class CoursePage:
    def __init__(self, page: Page):
        self.page = page

    def open(self, course_name: str) -> None:
        self.page.goto("/courses")
        self.page.get_by_role("link", name=course_name).first.click()

    def module_titles(self):
        # The Modules page gives module headers no accessible name, so fall back to CSS.
        return self.page.locator(".context_module .ig-header-title")


def test_student_sees_course_modules_in_order(student_page: Page):
    course = CoursePage(student_page)
    course.open(COURSE_NAME)
    expect(course.module_titles()).to_have_text(lesson_titles())
