# Arrow AI Agent Implementation

## Overview

This implementation creates an AI agent system for the Arrow narrative design tool using LangChain 1.0 and LangGraph. The system uses a supervisor pattern to orchestrate complex narrative design tasks.

## Architecture

```
User Message
    ↓
Supervisor Agent (Orchestrates workflow)
    ↓
Complexity Analyzer → Planner → Executor → Decider
                                    ↓
                              Arrow Tools
                                    ↓
                            WebSocket → Client
```

## Key Components

### 1. Supervisor Agent (`supervisor.py`)

Main workflow orchestrator that coordinates:

- **Complexity Analysis**: Determines if query is SIMPLE or COMPLEX
- **User Notification**: Sends status updates
- **Planning**: Creates task breakdown for complex queries
- **Execution**: Runs tasks using the executor agent
- **Decision**: Determines completion and next steps

### 2. Executor Agent (`executor.py`)

Executes tasks using Arrow tools. Uses LangChain 1.0's `create_agent` API with:

- Multiple Arrow tools for narrative design operations
- Async tool execution with WebSocket communication
- Automatic reasoning and tool selection

### 3. Arrow Tools (`tools/arrow_tools.py`)

Simple, focused tools for narrative operations:

**Node Creation:**

- `create_dialog_node`: Character dialogue
- `create_content_node`: Narrative text
- `create_hub_node`: Multiple choice branching
- `create_condition_node`: Conditional branching
- `create_variable_update_node`: Variable manipulation

**Connections:**

- `create_connection`: Link nodes together

**Resources:**

- `create_variable`: Global state variables
- `create_character`: Character entities

### 4. State Management (`states.py`)

Defines the workflow state:

- Session and message tracking
- Plan execution state
- Tool call tracking for async WebSocket communication

## WebSocket Tool Execution Flow

The implementation uses an elegant async pattern for tool execution:

1. **Tool Called**: Agent decides to use a tool (e.g., `create_dialog_node`)
2. **Send Function Call**: Tool sends function call via WebSocket with unique `request_id`
3. **Wait for Result**: Tool awaits on an `asyncio.Future`
4. **Client Executes**: Arrow client receives and executes the function
5. **Return Result**: Client sends `function_result` back via WebSocket
6. **Resume Execution**: Future is resolved, tool returns result to agent
7. **Continue**: Agent continues with next step

### Code Flow Example

```python
# 1. Tool is called by agent
result = await create_dialog_node(character_id=3, lines=["Hello!"])

# 2. send_function_call sends WebSocket message
await manager.send(session_id, {
    "type": "function_call",
    "request_id": "req_abc123",
    "function": "create_insert_node",
    "arguments": {...}
})

# 3. Tool waits on Future
future = asyncio.get_event_loop().create_future()
result = await asyncio.wait_for(future, timeout=30.0)

# 4. Client executes and responds
# (Arrow client processes function and sends result)

# 5. main.py receives function_result
set_function_result(request_id, success=True, result="Node created")

# 6. Future resolves, tool continues
return result  # "Node created"
```

## Key Features

### ✅ Simple Implementation

- No complex interrupt handling in LangGraph
- Uses standard `asyncio.Future` for waiting
- Clean separation of concerns

### ✅ Async WebSocket Communication

- Tools can await results from client
- 30-second timeout prevents hanging
- Clear error handling

### ✅ Full Plan Execution

- Executor receives the full plan, not just first task
- Agent can reason about entire task sequence
- Tools are called as needed to complete all tasks

### ✅ LangChain 1.0 Compatible

- Uses new `create_agent` API
- Follows latest LangChain patterns
- Future-proof implementation

## Usage Example

```python
# Client sends user message
{
    "type": "user_message",
    "message": "Create a dialog where Elena greets the player",
    "current_scene_id": 5
}

# System processes:
# 1. Complexity Analyzer: "SIMPLE"
# 2. Planner: Creates plan
# 3. Executor: Gets plan, uses create_dialog_node tool
# 4. Tool: Sends WebSocket function_call, waits
# 5. Client: Executes, returns result
# 6. Tool: Continues, agent completes
# 7. Decider: Marks task complete

# Client receives:
{
    "type": "chat_response",
    "message": "Created dialog node for Elena"
}
{
    "type": "end"
}
```

## Adding New Tools

To add a new Arrow tool:

1. Define the tool in `tools/arrow_tools.py`:

```python
@tool
async def my_new_tool(arg1: str, arg2: int) -> str:
    """Tool description for the LLM."""
    return await send_function_call("arrow_function_name", {
        "arg1": arg1,
        "arg2": arg2
    })
```

2. Add to `ARROW_TOOLS` list:

```python
ARROW_TOOLS = [
    create_dialog_node,
    create_content_node,
    my_new_tool,  # Add here
]
```

The executor agent will automatically have access to it!

## Configuration

**Timeout**: Tools wait up to 30 seconds for client response (configurable in `send_function_call`)

**Session Context**: Set via `set_context(session_id, scene_id)` before executor runs

**LLM Model**: Configured in `agent/models.py`

## Error Handling

- **Tool Timeout**: 30s timeout with clear error message
- **Client Errors**: Propagated as exceptions to agent
- **WebSocket Disconnect**: Graceful handling in manager
- **Agent Errors**: Caught and reported to user

## Future Enhancements

- [ ] Add more Arrow tools (scenes, jumps, etc.)
- [ ] Implement tool result caching
- [ ] Add streaming responses during tool execution
- [ ] Support batch function calls
- [ ] Add tool usage analytics
