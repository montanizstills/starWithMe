"""Module 3, exercise 1 (optional): let a browser-use agent explore the course.

Costs model calls. Needs: pip install browser-use, ANTHROPIC_API_KEY, ANTHROPIC_MODEL,
and TEST_STUDENT_PASSWORD. Not run in CI.
"""
import asyncio
import os
from pathlib import Path

from browser_use import Agent, ChatAnthropic

from conftest import student_login_id

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
    Path("runs").mkdir(exist_ok=True)
    agent.save_history("runs/explore_course.json")
    print(history.final_result())


if __name__ == "__main__":
    asyncio.run(main())
