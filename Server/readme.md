# Arrow AI Backend Server

## How to Run

### Install Dependencies
```bash
poetry install
```

### Configure Environment
Create a `.env` file in the `Server/` directory with your OpenAI API key:
```bash
OPENAI_API_KEY=your_api_key_here
```

### Start the Server
```bash
poetry run uvicorn Arrow_AI_Backend.main:app --reload --host 0.0.0.0 --port 8000
```

The server will start on `http://localhost:8000` and accept WebSocket connections at `ws://localhost:8000/ws/chat`.

---

## What Is This?

This is the **AI brain** behind The Narrative Penguins. It's a Python backend server that powers the AI chatbot integrated into Arrow's narrative editor. When you chat with the AI in Arrow, your messages come to this server, get processed by intelligent agents, and return as concrete actions that build your story.

## What It Does

The server receives natural language requests from Arrow (like "create a merchant character who sells potions") and transforms them into structured narrative elements (characters, dialog nodes, branching choices, connections). It does this through a sophisticated multi-agent system that understands narrative design.

### Core Components

#### 1. WebSocket Server (`main.py`)
- Handles real-time bidirectional communication with Arrow
- Manages user sessions and project state
- Routes messages between the client and AI agents
- Sends function calls to Arrow and receives results

#### 2. Multi-Agent System (`agent/`)

**Complexity Analyzer** (`agents/complexity_analyzer.py`)
- Analyzes incoming user requests
- Classifies them as SIMPLE (single action) or COMPLEX (multi-step)
- Routes simple requests directly to execution
- Sends complex requests to the planner

**Planner** (`agents/planner.py`)
- Creates strategic plans for complex narrative requests
- Breaks down requests into logical, ordered steps
- Checks what resources already exist to avoid duplication
- Plans the full narrative flow: entry points, connections, branches
- Understands narrative patterns (character introductions, branching dialogs, stat tracking, etc.)

**Executor** (`agents/executor.py`)
- Takes plans and executes them step-by-step
- Calls Arrow tools to create nodes, characters, variables, and connections
- Handles errors autonomously (creates missing resources without asking)
- Verifies each step before moving to the next
- Works through complex multi-step sequences intelligently

**Supervisor** (`agents/supervisor.py`)
- Orchestrates the entire workflow
- Routes requests through: Analyze → Plan → Execute
- Manages state throughout the process
- Sends real-time updates to the user
- Coordinates session management and project context

#### 3. Function Calling System (`agent/tools/`)

**Arrow Tools** (`arrow_tools.py`)
- Defines all the functions the AI can call to modify Arrow projects
- Each tool represents an action: create node, add character, make connection, etc.
- Tools communicate with Arrow via WebSocket function calls
- Handles async request/response cycles with Arrow
- Maintains project context (current scene, project state, etc.)

Key functions include:
- `create_dialog_node()` - Create character dialog with branching choices
- `create_content_node()` - Create narrative content/description
- `create_character()` - Add characters to the story
- `create_variable()` - Set up state tracking variables
- `create_connection()` - Connect nodes together
- `get_character()`, `get_variable()` - Query existing resources
- And many more for complete narrative control

#### 4. State Management (`states.py`)

Defines the data structures that flow through the agent pipeline:
- User input and session info
- Complexity classification
- Plans (list of steps)
- Execution history
- Project context (scene IDs, selected nodes, Arrow file content)

#### 5. Connection Manager (`manager.py`)

Manages WebSocket connections:
- Tracks active sessions
- Handles connection/disconnection
- Sends messages safely with error handling
- Manages multiple simultaneous user sessions

### How It All Works Together

1. **User sends message** in Arrow's chat interface
2. **WebSocket receives** the message along with project context (current scene, selected nodes, project file)
3. **Supervisor starts** the workflow
4. **Complexity Analyzer** determines if it's simple or complex
5. **Planner** (if complex) creates a step-by-step plan
6. **Executor** runs the plan using Arrow tools:
   - Calls functions like `create_dialog_node()`
   - Sends function call to Arrow via WebSocket
   - Arrow executes the function (creates the actual node)
   - Arrow sends back result (success/failure, new node ID)
   - Executor uses that result for next steps
7. **Supervisor** sends progress updates back to user
8. **User sees nodes appear** in real-time in Arrow

### Example Flow

**User Request**: "Create a merchant who sells health potions"

**Server Processing**:
1. Complexity Analyzer: "COMPLEX - requires character, dialog, and choices"
2. Planner creates steps:
   - Check if merchant character exists
   - Create merchant character if needed
   - Create dialog node for merchant offering potions
   - Create interaction node with buy/decline choices
   - Connect nodes to story flow
3. Executor runs each step:
   - Calls `get_character(name="merchant")` → doesn't exist
   - Calls `create_character(name="merchant", ...)` → gets character ID
   - Calls `create_dialog_node(character_id=..., text="...")` → gets dialog node ID
   - Calls `create_interaction_node(options=["Buy", "Decline"])` → gets interaction ID
   - Calls `create_connection(from_node=..., to_node=...)` multiple times
4. Supervisor sends updates to user
5. Result: Complete merchant interaction appears in Arrow

## Technology Stack

- **FastAPI** - Modern async web framework for Python
- **WebSockets** - Real-time bidirectional communication
- **LangChain** - Framework for building LLM-powered agents
- **LangGraph** - For building multi-agent workflows
- **Pydantic** - Data validation and structured outputs
- **Poetry** - Dependency management

## Project Structure

```
Server/
├── Arrow_AI_Backend/
│   ├── main.py                 # WebSocket server entry point
│   ├── manager.py              # WebSocket connection manager
│   ├── schemas.py              # Message schemas
│   ├── agent/
│   │   ├── agents/
│   │   │   ├── supervisor.py         # Main orchestrator
│   │   │   ├── complexity_analyzer.py # Request classifier
│   │   │   ├── planner.py            # Plan creator
│   │   │   └── executor.py           # Task executor
│   │   ├── tools/
│   │   │   └── arrow_tools.py        # Arrow manipulation functions
│   │   ├── states.py           # Agent state definitions
│   │   └── models.py           # LLM model configuration
│   └── lib/                    # Utility functions
├── pyproject.toml              # Poetry dependencies
└── poetry.lock                 # Locked dependencies
```

## Key Features

- **Real-time collaboration** - See changes as the AI builds them
- **Context awareness** - AI knows your entire project state
- **Autonomous execution** - Handles errors and missing resources automatically
- **Session management** - Multiple users can work simultaneously
- **Structured outputs** - AI generates valid narrative structures, not just text
- **Function calling** - AI reasons about which functions to call and when

This server transforms natural language into interactive narratives through intelligent planning and autonomous execution.
