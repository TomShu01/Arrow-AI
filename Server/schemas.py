from pydantic import BaseModel
from typing import Optional, Any

class WSMessage(BaseModel):
    type: str
    data: Optional[Any] = None

class MessageStartData(BaseModel):
    conversationId: Optional[str]
    text: str

class PingData(BaseModel):
    timestamp: int
