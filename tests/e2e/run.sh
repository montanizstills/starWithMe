#!/usr/bin/env bash
# Student test runner (SWM-226 in CI, SWM-225 on staging).
#   CANVAS_URL=... TEST_STUDENT_PASSWORD=... tests/e2e/run.sh
# Results land in tests/e2e/test-results (JUnit + failure screenshots).
set -euo pipefail
cd "$(dirname "$0")"
[ -d .venv ] || python3 -m venv .venv
.venv/bin/pip install -q -r requirements.txt
.venv/bin/playwright install ${PLAYWRIGHT_DEPS:+--with-deps} chromium
exec .venv/bin/pytest "$@"
