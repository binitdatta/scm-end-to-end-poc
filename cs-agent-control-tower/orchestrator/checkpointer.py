# """
# orchestrator/checkpointer.py
# Thin wrapper around LangGraph's SqliteSaver so the rest of the app
# imports from one place and the DB path comes from .env.
# """
#
# import os
# import sqlite3
#
# from langgraph.checkpoint.sqlite import SqliteSaver
#
# _saver: SqliteSaver | None = None
#
#
# def get_checkpointer() -> SqliteSaver:
#     global _saver
#     if _saver is None:
#         db_path = os.getenv("CHECKPOINT_DB_PATH", "./agent_checkpoints.db")
#         conn = sqlite3.connect(db_path, check_same_thread=False)
#         _saver = SqliteSaver(conn)
#     return _saver

"""
orchestrator/checkpointer.py

The SQLite checkpointer is intentionally disabled.

Why: LangGraph's SqliteSaver replays the graph from the last checkpoint
when graph.stream() is called with the same thread_id. In this app the
HITL gate blocks the agent thread directly via threading.Event inside the
skill — the graph never suspends at the LangGraph level. When the human
approves and the skill returns, the graph continues naturally through the
remaining nodes without any checkpoint involvement.

Using the checkpointer causes node_plan to re-execute on every run
(because the last checkpoint is always plan_run), resetting
current_step_index to 0 and making the agent repeat step 1 forever.

For production use with true graph suspension, replace this with a
Redis-backed checkpointer and remove the threading.Event HITL pattern.
"""


def get_checkpointer():
    return None