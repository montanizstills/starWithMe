import shutil
import sys
from pathlib import Path

import pytest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "src"))
sys.path.insert(0, str(HERE))

REPO = HERE.parents[2]
EXAMPLE = REPO / "courses" / "example-playwright-browser-use"
MINI = HERE / "fixtures" / "mini-course"


@pytest.fixture
def mini(tmp_path):
    """A writable copy of the mini course, so a test can break it."""
    dst = tmp_path / "mini-course"
    shutil.copytree(MINI, dst)
    return dst


@pytest.fixture(autouse=True)
def forget_secrets():
    from courses import canvas
    yield
    canvas._SECRETS.clear()
