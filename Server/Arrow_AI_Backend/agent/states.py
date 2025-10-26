"""
State, and shared data type definitions for the agents
"""

import operator
from typing import Annotated, List, Tuple, Dict, Any, Optional
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
    past_steps: Annotated[List[Tuple], operator.add]
    response: str
    replan_reason: str  # Reason why replanning is needed
    
    # Tool execution tracking for interrupts
    pending_request_id: Optional[str]  # ID of function call waiting for result
    function_result: Optional[Dict[str, Any]]  # Result from client
    current_scene_id: Optional[int]  # Current scene context
    arrow_file: Optional[str]  # Current arrow file data as JSON string