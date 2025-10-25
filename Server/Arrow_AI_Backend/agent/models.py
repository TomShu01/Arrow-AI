from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic

# Load environment variables
load_dotenv()

# Use Anthropic as default, fallback to OpenAI if needed
llm = ChatOpenAI(model="gpt-4o-mini")
llm_smart = ChatAnthropic(model="claude-sonnet-4-20250514")
