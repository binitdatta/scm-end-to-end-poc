"""
observability/context.py

Carries "who is making this call" and "which run is this part of" across
the whole call chain — Flask request thread, the background agent-run
thread, scm_client HTTP calls, and Anthropic LLM calls — without having
to thread extra parameters through every function signature in
scm_client.py, skills/*.py, planner.py, and narrator.py.

ContextVars do NOT automatically propagate into a new thread. Anywhere a
new threading.Thread is started (currently: app.py's _run_agent), the
target function must call .set() again at its own top, using the values
captured before the thread was spawned.
"""

from __future__ import annotations

import contextvars

current_user_id: contextvars.ContextVar[str] = contextvars.ContextVar(
    "current_user_id", default="anonymous"
)

current_run_id: contextvars.ContextVar[str | None] = contextvars.ContextVar(
    "current_run_id", default=None
)


def get_user_id() -> str:
    return current_user_id.get()


def get_run_id() -> str | None:
    return current_run_id.get()
