import asyncio
from typing import AsyncGenerator

async def generate_llm_stream(prompt: str) -> AsyncGenerator[str, None]:
    """
    Mock LLM stream that yields partial text chunks.
    Replace this with a call to an actual model (e.g., OpenAI, Ollama, vLLM, etc.)
    """
    fake_response = f"This is the LLM response to: '{prompt}'"
    for word in fake_response.split():
        await asyncio.sleep(0.2)
        yield word + " "
