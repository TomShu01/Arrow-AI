"""
State, and shared data type definitions for the agents
"""

import operator
from typing import Annotated, List, Tuple
from typing_extensions import TypedDict
from pydantic import BaseModel, Field


class Plan(BaseModel):
    """Plan to follow in future"""

    steps: List[str] = Field(
        description="different steps to follow, should be in sorted order"
    )


class PlanExecute(TypedDict):
    session_id: str
    message_id: str
    input: str
    complexity: str  # "SIMPLE" or "COMPLEX"
    plan: List[str]  # Remaining tasks to complete
    completed_tasks: List[str]  # Tasks that have been marked as done
    past_steps: Annotated[List[Tuple], operator.add]
    response: str
    replan_reason: str  # Reason why replanning is needed