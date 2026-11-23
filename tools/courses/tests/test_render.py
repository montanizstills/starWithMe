from courses import render
from fake_canvas import sanitize


def test_fenced_code_is_preformatted():
    html = render.md_to_html("```python\nprint('<hi>')\n```\n")
    assert html.startswith('<pre><code class="language-python">') and "&lt;hi&gt;" in html


def test_inline_answer_has_no_paragraph():
    assert render.md_inline("`x`") == "<code>x</code>"
    assert render.md_plain("Use `expect()` & wait") == "Use expect() & wait"


def test_same_html_ignores_sanitizer_noise():
    html = render.md_to_html("Hello \"world\"\n\n| a | b |\n|---|---|\n| 1 | 2 |\n")
    assert render.same_html(sanitize(html), html)
    assert not render.same_html(sanitize(html), html.replace("world", "there"))
