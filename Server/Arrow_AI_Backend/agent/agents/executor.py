"""
Executor Agent - Executes tasks using Arrow tools
Follows the new LangChain 1.0 API with create_agent
"""

from Arrow_AI_Backend.agent.models import llm
from langchain.agents import create_agent
from Arrow_AI_Backend.agent.tools.arrow_tools import ARROW_TOOLS

# System prompt for the executor
EXECUTOR_PROMPT = """You are an AI assistant that executes narrative design tasks using Arrow tools.

Your job is to:
1. Analyze the given task
2. Use the available tools to complete it
3. Create nodes, connections, variables, and characters as needed
4. Provide clear feedback about what you've done

Available tools allow you to:
- Create dialog, content, hub, condition, and variable update nodes
- Create connections between nodes
- Create variables and characters
- Manage the narrative structure

Be concise and focused on completing the task."""

# Create the executor agent with Arrow tools
agent_executor = create_agent(
    model=llm,
    tools=ARROW_TOOLS,
    system_prompt=EXECUTOR_PROMPT
)
