"""
Query Complexity Analyzer
Determines if a user request is SIMPLE (single action) or COMPLEX (requires planning)
"""

from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field
from Arrow_AI_Backend.agent.models import llm


class QueryComplexity(BaseModel):
    """Classification of query complexity"""
    
    complexity: str = Field(
        description="Either 'SIMPLE' or 'COMPLEX'. SIMPLE means single action, COMPLEX means multiple steps needed"
    )
    reasoning: str = Field(
        description="Brief explanation of why this query is simple or complex"
    )


complexity_prompt = ChatPromptTemplate.from_messages([
    ("system", """You are analyzing user requests for a narrative design tool called Arrow.

Classify the request as either SIMPLE or COMPLEX:

SIMPLE requests:
- Single node creation (e.g., "add a dialog node", "create a content node")
- Single property update (e.g., "change the character name to Elena", "update the text")
- Single deletion (e.g., "delete node 5", "remove this character")
- Single connection (e.g., "connect node 3 to node 7")
- Simple queries about the current state

COMPLEX requests:
- Multiple nodes with connections (e.g., "create a branching conversation with 3 choices")
- Complete narrative sequences (e.g., "add a combat system with health tracking")
- Multiple operations across different resources (e.g., "create a new character and add their dialog")
- Conditional flows with multiple paths
- Anything requiring 3+ distinct operations

Examples:

User: "Add a dialog node where the protagonist asks about the ancient artifact"
Classification: SIMPLE
Reasoning: Single dialog node creation with specified content

User: "Create a dialog where Elena offers help, then add player choices to accept or refuse"
Classification: COMPLEX
Reasoning: Requires creating dialog node, hub node, and connecting them - multiple steps

User: "Change the character name to Marcus"
Classification: SIMPLE
Reasoning: Single update operation on one character

User: "Add a combat system where the player can attack, defend, or flee, and track health"
Classification: COMPLEX
Reasoning: Requires creating variables, multiple nodes for options, condition nodes for health, connections - many steps

User: "Delete node 12"
Classification: SIMPLE
Reasoning: Single deletion operation

User: "Create a conversation between two characters about their quest, with player choices for how to respond"
Classification: COMPLEX
Reasoning: Multiple dialog nodes, character setup, hub nodes, connections - requires planning"""),
    ("user", "{input}")
])

complexity_analyzer = complexity_prompt | llm.with_structured_output(QueryComplexity)

