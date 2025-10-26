"""
Executor Agent - Executes tasks using Arrow tools
Follows the new LangChain 1.0 API with create_agent
"""

from Arrow_AI_Backend.agent.models import llm_smart
from langchain.agents import create_agent
from Arrow_AI_Backend.agent.tools.arrow_tools import ARROW_TOOLS

# System prompt for the executor
EXECUTOR_PROMPT = """You are a task executor for Arrow narrative design. Execute the given plan step-by-step using tools.

RULES:
1. Execute steps in exact order - do step 1, then step 2, then step 3, etc.
2. Do NOT skip steps. Execute every single step as written.
3. After each tool call, check the result before moving to the next step.
4. If a step says "check if X exists", use a query tool (get_character, get_variable, etc.)
5. Use the results from earlier steps in later steps (e.g., use the character ID you found/created).

When done, summarize what you accomplished."""

# Create the executor agent with Arrow tools
# Using llm_smart (lower temperature) for more consistent, deterministic execution
agent_executor = create_agent(
    model=llm_smart,
    tools=ARROW_TOOLS,
    system_prompt=EXECUTOR_PROMPT
)
