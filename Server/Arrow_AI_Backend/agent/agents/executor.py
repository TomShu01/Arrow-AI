
from Arrow_AI_Backend.agent.models import llm
from langchain_community.tools.tavily_search import TavilySearchResults
from langgraph.prebuilt import create_react_agent
from Arrow_AI_Backend.agent.tools.test_tool import multiply

tools = [multiply] # TODO: Add TavilySearchResults(max_results=3) and other tools here

# Choose the LLM that will drive the agent
prompt = "You are a helpful assistant."
agent_executor = create_react_agent(llm, tools, prompt=prompt)

