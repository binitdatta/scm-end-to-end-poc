"""
orchestrator/state.py
Defines AgentState — the single shared object that flows through every
LangGraph node.  All fields use Python 3.12 type hints.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class RunStatus(str, Enum):
    PENDING   = "pending"
    PLANNING  = "planning"
    RUNNING   = "running"
    PAUSED    = "paused"       # waiting for human approval
    APPROVED  = "approved"     # human approved, ready to resume
    REJECTED  = "rejected"     # human rejected
    COMPLETED = "completed"
    FAILED    = "failed"


class StepStatus(str, Enum):
    PENDING   = "pending"
    RUNNING   = "running"
    DONE      = "done"
    SKIPPED   = "skipped"
    FAILED    = "failed"
    WAITING   = "waiting"      # waiting for HITL


@dataclass
class StepResult:
    skill: str
    status: StepStatus
    payload: dict[str, Any]
    error: str | None = None
    confidence: float = 1.0
    hitl_required: bool = False
    hitl_reason: str | None = None


@dataclass
class HITLRequest:
    gate_id: str
    skill: str
    action: str
    recommendation: str
    confidence: float
    payload: dict[str, Any]
    decision: str | None = None   # "approve" | "reject" | "override"
    override_payload: dict[str, Any] | None = None


@dataclass
class AgentState:
    # Unique run identifier
    run_id: str = field(default_factory=lambda: str(uuid.uuid4()))

    # Natural language goal from the operator
    goal: str = ""

    # Claude's decomposed plan
    plan: list[dict[str, Any]] = field(default_factory=list)

    # Completed step results
    steps: list[StepResult] = field(default_factory=list)

    # IDs created during the run (for chaining across skills)
    context: dict[str, Any] = field(default_factory=dict)

    # Current HITL request, if paused
    hitl_request: HITLRequest | None = None

    # Overall run status
    status: RunStatus = RunStatus.PENDING

    # Log messages streamed to the UI
    log: list[str] = field(default_factory=list)

    # Final narrative report
    report: str = ""

    # Error message if failed
    error: str | None = None

    # Index into plan — which step we are currently executing
    current_step_index: int = 0
