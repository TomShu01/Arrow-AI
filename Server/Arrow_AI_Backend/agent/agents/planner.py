

from langchain_core.prompts import ChatPromptTemplate
from Arrow_AI_Backend.agent.models import llm
from Arrow_AI_Backend.agent.states import Plan

planner_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            """You are planning how to fulfill a user's request for Arrow, a narrative design tool.

Create a simple step-by-step plan to accomplish the user's objective. Each step should be:
- A single, clear action
- Executable with the available Arrow functions (create nodes, update properties, make connections, etc.)
- Include all necessary details (don't skip information)
- In logical order

Available operations in Arrow:
- Create nodes (dialog, content, hub, condition, variable_update, etc.)
- Update node properties
- Create connections between nodes
- Create/update variables and characters
- Create/update scenes

Example:
User: "Create a dialog where Elena offers help, then add player choices to accept or refuse"

Plan:
1. Create a dialog node with character Elena saying she offers to help
2. Create a hub node with two options: "Accept help" and "Refuse help"
3. Connect the dialog node to the hub node

Keep plans simple and focused on the specific request.""",
        ),
        ("placeholder", "{messages}"),
    ]
)
planner = planner_prompt | llm.with_structured_output(Plan)

