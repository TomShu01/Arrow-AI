from pydantic import BaseModel
from typing import Optional, Any, List, Dict


class FileSyncMessage(BaseModel):
    type: str  # "file_sync"
    project_id: int
    arrow_content: str
    timestamp: int

class HistoryItem(BaseModel):
    message: str
    output: str

class UserMessage(BaseModel):
    type: str  # "user_message"
    message: str
    history: List[HistoryItem] = []
    selected_node_ids: List[int] = []
    current_scene_id: Optional[int] = None
    current_project_id: Optional[int] = None

class FunctionResultMessage(BaseModel):
    type: str  # "function_result"
    request_id: str
    success: bool
    result: Any = ""
    error: str = ""

class StopMessage(BaseModel):
    type: str  # "stop"


class ConnectedMessage(BaseModel):
    type: str = "connected"
    data: Dict[str, Any]

class ChatResponseMessage(BaseModel):
    type: str = "chat_response"
    message: str

class FunctionCallMessage(BaseModel):
    type: str = "function_call"
    request_id: str
    function: str
    arguments: Dict[str, Any]

class EndMessage(BaseModel):
    type: str = "end"
