"""Markdown -> HTML for Canvas text fields, and an HTML comparison that
survives Canvas's sanitizer.

The one conversion the tool makes (SWM-204): fenced code becomes
<pre><code>, so code renders as preformatted text in pages and quiz questions.
"""
from __future__ import annotations

import html
import re
from html.parser import HTMLParser

import markdown

EXTENSIONS = ["fenced_code", "tables", "sane_lists"]


def md_to_html(text: str) -> str:
    if not text:
        return ""
    return markdown.markdown(text, extensions=EXTENSIONS, output_format="html")


def md_inline(text: str) -> str:
    """For short text such as answers: no wrapping <p> when it is one paragraph."""
    out = md_to_html(text).strip()
    m = re.fullmatch(r"<p>(.*)</p>", out, flags=re.S)
    if m and "<p>" not in m.group(1):
        return m.group(1)
    return out


def md_plain(text: str) -> str:
    """Visible text of a Markdown snippet, for Canvas's plain-text fields."""
    return " ".join(html.unescape(re.sub(r"<[^>]+>", "", md_inline(text))).split())


class _Canon(HTMLParser):
    """Tags and visible text only: attributes, whitespace and entity spelling
    are ignored, because Canvas rewrites them when it sanitizes HTML."""

    IGNORED = {"tbody", "thead", "span"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tokens: list = []

    def handle_starttag(self, tag, attrs):
        if tag not in self.IGNORED:
            self.tokens.append("<" + tag)

    def handle_startendtag(self, tag, attrs):
        if tag not in self.IGNORED:
            self.tokens.append("<" + tag + "/")

    def handle_endtag(self, tag):
        if tag not in self.IGNORED:
            self.tokens.append("/" + tag)

    def handle_data(self, data):
        text = " ".join(data.split())
        if text:
            if self.tokens and self.tokens[-1].startswith("#"):
                self.tokens[-1] += " " + text
            else:
                self.tokens.append("#" + text)


def canon(fragment) -> tuple:
    if not fragment:
        return ()
    p = _Canon()
    p.feed(str(fragment))
    p.close()
    # A lone paragraph wrapper is not a difference Canvas cares about.
    t = p.tokens
    if len(t) >= 2 and t[0] == "<p" and t[-1] == "/p" and t.count("<p") == 1:
        t = t[1:-1]
    return tuple(t)


def same_html(a, b) -> bool:
    return canon(a) == canon(b)
