

from langchain_core.prompts import ChatPromptTemplate
from Arrow_AI_Backend.agent.models import llm
from Arrow_AI_Backend.agent.states import Plan

planner_prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            """You are planning how to fulfill a user's request for Arrow, a narrative design tool.

Create a simple step-by-step plan to accomplish the user's objective. Each step should be:
- A single, clear action
- Executable with the available Arrow functions
- Include all necessary details (don't skip information)
- In logical order

## Available Operations

### Node Operations
- create_insert_node: Create new narrative/logic nodes
- update_node: Modify node properties and data
- delete_node: Remove nodes
- create_connection: Connect nodes to create narrative flow
- delete_connection: Remove connections between nodes

### Scene Operations
- create_scene: Create new scenes or macros
- update_scene: Modify scene properties
- delete_scene: Remove scenes
- set_scene_entry: Set scene entry point
- set_project_entry: Set project main entry point

### Variable Operations
- create_variable: Create global variables (num, str, bool)
- update_variable: Modify variable properties
- delete_variable: Remove variables

### Character Operations
- create_character: Create character entities with tags
- update_character: Modify character properties and tags
- delete_character: Remove characters

## Available Node Types

**Narrative Nodes:**
- dialog: Multi-line character speech
- monolog: Single line character speech
- content: Descriptive text/narration
- user_input: Prompt player for input

**Branching/Logic Nodes:**
- hub: Multiple choice player decisions
- interaction: Interactive action choices
- condition: Branch based on variable comparison
- tag_match/tag_pass: Branch based on character tags
- randomizer: Random path selection
- sequencer: Sequential path cycling

**Control Flow:**
- jump: Jump to nodes/scenes/markers
- marker: Named jump targets
- entry: Scene entry point
- frame: Visual grouping container
- macro_use: Call reusable scenes

**State Management:**
- variable_update: Modify variable values
- tag_edit: Modify character tags
- generator: Generate random values

## Planning Guidelines

1. **Start with dependencies**: Create variables/characters before using them in nodes
2. **Create before connect**: Create all nodes before making connections
3. **Logical flow**: Build narrative paths step by step
4. **Use appropriate node types**: Match the right node to the task
5. **Consider entry points**: Ensure scenes have proper entry nodes

## Example Plans

User: "Create a dialog where Elena offers help, then add player choices to accept or refuse"
Plan:
1. Create a dialog node with character Elena offering to help
2. Create a hub node with two options: "Accept help" and "Refuse help"
3. Connect the dialog node to the hub node

User: "Add a health system that tracks player health from 0 to 100"
Plan:
1. Create a number variable called "player_health" with initial value 100
2. Create a condition node to check if player_health <= 0
3. Create nodes for game over and continue scenarios
4. Connect condition to both outcome nodes

Keep plans simple, focused, and actionable.""",
        ),
        ("placeholder", "{messages}"),
    ]
)
planner = planner_prompt | llm.with_structured_output(Plan)

