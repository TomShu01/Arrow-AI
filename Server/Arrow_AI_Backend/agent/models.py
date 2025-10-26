from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
import os

# Load environment variables
load_dotenv()

if not os.getenv("OPENAI_API_KEY"):
    raise ValueError(
        "OPENAI_API_KEY not found in environment variables. "
        "Please create a .env file with OPENAI_API_KEY=your_key_here"
    )

llm = ChatOpenAI(
    model="gpt-4o",
    temperature=0.7,
)

llm_smart = ChatOpenAI(
    model="gpt-4o",
    temperature=0.5,
)
