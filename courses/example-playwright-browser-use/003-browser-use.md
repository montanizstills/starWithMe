# Module 3: Agent-driven exploration with browser-use

Playwright does exactly what you script. [browser-use](https://github.com/browser-use/browser-use) is different: you give an AI agent a task in plain language, and it decides what to click. That makes it good for **exploring** an app you don't know yet. Playwright stays the right tool for **repeatable tests**.

In this module, an agent explores your local Canvas as the test student. You then turn what it found into a Playwright test.

## Agents explore, tests verify

| | Playwright test | browser-use agent |
| --- | --- | --- |
| You write | Exact steps and assertions | A goal in plain language |
| Same result every run | Yes | Not guaranteed |
| Cost per run | Free | Model calls (unless replayed) |
| Best for | CI, regression checks | Exploring, finding paths, drafting tests |

The usual workflow: let the agent find a path, save its history, then write or generate a Playwright test that checks the same path on every run.

## Set up

browser-use needs Python 3.11+ and a language model. Any of these work:

- **A provider key**, for example `ChatAnthropic` with `ANTHROPIC_API_KEY` set. Each run costs a little.
- **A local model through Ollama.** Free, but needs a capable machine.

```bash
pip install browser-use
```

Keep API keys in your local `.env` or password manager, never in the course files.

## Your first agent

```python
import asyncio
import os

from browser_use import Agent, ChatAnthropic

from conftest import student_login_id  # reads course.yml

TASK = """
Go to {url}/login/canvas and log in with the username x_login and password x_password.
Open the course "Browser automation with Playwright and browser-use".
List the titles of its modules, in order.
"""

async def main():
    login_id = student_login_id()
    agent = Agent(
        task=TASK.format(url=os.environ.get("CANVAS_URL", "http://localhost:3000")),
        llm=ChatAnthropic(model=os.environ["ANTHROPIC_MODEL"]),
        sensitive_data={
            "x_login": login_id,
            "x_password": os.environ["TEST_STUDENT_PASSWORD"],
        },
    )
    history = await agent.run()
    agent.save_history("runs/explore_course.json")
    print(history.final_result())

asyncio.run(main())
```

`sensitive_data` keeps the real credentials out of the prompt: the model only sees `x_login` and `x_password`, and browser-use types the real values.

## Replaying without the model

A saved history can be replayed: the same clicks and typing, without a model call for each step.

```python
results = await Agent(task="", llm=llm).load_and_rerun(
    "runs/explore_course.json", skip_failures=False
)
```

If Canvas changes, the replay stops at the first step it can't match. That makes a replay a cheap smoke check, but a Playwright test is still clearer and fully free.

The saved history can include page snapshots that show the student's data. Keep the `runs/` folder out of git (it is in `.gitignore`).

## Exercises

1. **Explore (optional; costs model calls).** Run `python explore_agent.py` with your model settings. Read the agent's final answer and compare it with the four module titles you checked in Module 2.
2. **From exploration to test.** Look at the steps in `runs/explore_course.json`. Write `test_03_agent_path.py`, a Playwright test that follows the same path and asserts the same module titles. This is the graded exercise, and it needs no model.
3. **Explore something new.** Give the agent a task you haven't scripted, such as "find where the student sees their grades". Turn the path it finds into a test.

## Key points

- Agents explore; tests verify. Keep agents out of CI unless you replay them.
- Pass credentials through `sensitive_data`, never in the task text.
- Saved agent histories may contain personal data; keep them private.
