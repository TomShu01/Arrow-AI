from typing import Literal

from pydantic import BaseModel, Field
from langchain_core.prompts import ChatPromptTemplate
from Arrow_AI_Backend.agent.models import llm


class Decision(BaseModel):
    """Decision after executing a step."""
    
    completed_count: int = Field(
        description="How many tasks from the START of the remaining plan are completed (e.g., 0=none, 1=first task, 2=first two tasks, etc.)"
    )
    is_replan_needed: bool = Field(
        default=False,
        description="True if the plan needs to be rewritten"
    )
    replan_reason: str = Field(
        default="",
        description="Reason why replanning is needed (only if is_replan_needed=True)"
    )
    final_message: str = Field(
        default="",
        description="Final message to user when all tasks are complete (only when all remaining tasks are done)"
    )


decider_prompt = ChatPromptTemplate.from_template(
    """Review the execution and decide how many tasks are complete.

User's goal: {input}

Remaining tasks: {plan}

Completed tasks so far: {completed_tasks}

Last execution: {past_steps}

Your job: Determine how many tasks from the START of the remaining plan are now complete.

Examples:
- If only the first task is done: completed_count=1
- If the first 3 tasks are done: completed_count=3  
- If no tasks are done yet: completed_count=0
- If ALL remaining tasks are done: completed_count=<length of remaining plan>

Also check if replanning is needed (only if the current plan is broken/invalid).

When all remaining tasks are complete, provide a final_message summarizing what was accomplished."""
)


decider = decider_prompt | llm.with_structured_output(Decision)