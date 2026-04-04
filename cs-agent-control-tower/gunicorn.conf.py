"""
gunicorn.conf.py
Gunicorn configuration for cs-agent-control-tower.

Worker strategy: gthread
  - Runs 1 worker process with 8 threads.
  - Threads share memory within the worker, so _runs dict and HITL gates are
    consistent across all requests.
  - SSE streaming works correctly — each response runs in its own thread.
  - Avoids gevent monkey-patching which breaks pika's blocking connection.

workers=1 is intentional for this PoC:
  - The in-memory _runs registry and hitl gate store are per-process.
  - With workers>1 a run started in worker A is invisible to worker B.
  - For production, back state with Redis and you can scale freely.
"""

import os
from dotenv import load_dotenv
load_dotenv()

# ── Binding ────────────────────────────────────────────────────────────────
port = os.getenv("FLASK_PORT", "9000")
bind = f"0.0.0.0:{port}"

# ── Worker config ──────────────────────────────────────────────────────────
worker_class = "gthread"
workers      = 1        # keep at 1 — in-memory state is per-process
threads      = 8        # handles concurrent SSE streams + agent threads
timeout      = 300      # long timeout for SSE streams and HITL waits
keepalive    = 5

# ── Logging ────────────────────────────────────────────────────────────────
loglevel          = os.getenv("LOG_LEVEL", "info").lower()
accesslog         = "-"
errorlog          = "-"
access_log_format = '%(h)s "%(r)s" %(s)s %(b)s'

# ── Hooks ──────────────────────────────────────────────────────────────────

def post_fork(server, worker):
    """
    Called inside the worker process after fork.
    This is the correct place to start background threads under gunicorn.
    Threads started before fork() are silently lost in child workers.
    """
    from messaging.consumer import start_consumer
    start_consumer()
    server.log.info("RabbitMQ consumer started in worker pid=%d", worker.pid)


def on_starting(server):
    server.log.info("SCM Agent Control Tower starting with gunicorn (gthread worker)")


def worker_exit(server, worker):
    server.log.info("Worker pid=%d exiting", worker.pid)