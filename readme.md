# The Narrative Penguins

**AI-powered interactive storytelling at the speed of imagination.**

## The Problem

Creating branching narratives for games is tedious. Every dialog needs a character, every choice needs connections, every branch needs to merge back. Traditional visual editors make you manually drag nodes, wire connections, and click through endless menus.

## Our Solution

We added an **AI chatbot directly into Arrow**—a visual narrative design tool. Now you can chat with your editor like a colleague: *"Add a merchant who sells magical items with player choices."* The AI understands your project, creates the nodes, and connects everything automatically.

## How It Works

### The Chat Interface

We integrated a chatbot into Arrow's editor that maintains full awareness of your project:
- Knows all your characters, variables, and story structure
- Sees which nodes you have selected
- Understands context when you say "change this" or "add a dialog here"
- Responds in real-time as it builds your story

You type natural requests, and it builds the narrative structure for you.

### Function Calling System

This is where the magic happens. The AI doesn't just respond with text—it **calls functions that modify your project**:

- `create_dialog_node()` - Creates character dialog with multiple choice branches
- `create_character()` - Adds characters to your story
- `create_variable()` - Sets up state tracking (health, karma, inventory, etc.)
- `create_connection()` - Wires nodes together into narrative flow
- `get_character()` - Queries existing resources to avoid duplicates

**The key innovation**: The AI decides *which* functions to call, *when* to call them, and *in what order*—based on understanding narrative structure. It's not following rigid scripts; it's reasoning about your story.

When you request something, the chatbot:
1. Analyzes your request
2. Determines what functions are needed
3. Calls them in the right sequence
4. Sends updates back to Arrow via WebSocket
5. Your editor refreshes with the new nodes

### Multi-Agent Backend

Behind the chatbot, multiple specialized AI agents collaborate:

**Complexity Analyzer** - Figures out if your request is simple (one action) or complex (needs multi-step planning)

**Planner** - For complex requests, creates a strategic blueprint of what needs to happen

**Executor** - Takes the plan and actually calls the functions to build your story, handling errors autonomously

**Supervisor** - Orchestrates the workflow and manages real-time communication

This pipeline ensures simple requests are handled instantly while complex requests get proper planning.

## See It In Action

**You**: *"Create a mysterious stranger who offers a quest, with options to accept, ask for details, or decline."*

**What the AI does**:
1. Calls `get_character("mysterious stranger")` to check if they exist
2. Calls `create_character()` to add the stranger
3. Calls `create_content_node()` for the stranger's appearance
4. Calls `create_dialog_node()` for the quest offer
5. Calls `create_interaction_node()` with 3 choices
6. Calls `create_connection()` multiple times to wire everything together
7. Sends updates to Arrow in real-time

**Result**: Complete quest system appears in ~10 seconds, fully connected and ready to customize.

**Manual way**: 5-10 minutes of clicking  
**With AI chatbot**: ~10 seconds

## The Tech Stack

**Frontend**: Arrow (Godot) + integrated chat UI + WebSocket client  
**Backend**: FastAPI + LangChain agents + function calling system  
**Communication**: Real-time WebSocket with bidirectional function calls

The WebSocket protocol handles:
- User messages to AI
- AI function calls to Arrow
- Arrow function results back to AI
- Real-time progress updates

## Why It Matters

Traditional tools require learning complex UIs. Our chatbot shifts the paradigm: **describe your creative intent, let the AI handle the implementation**. Writers focus on narrative. Designers iterate rapidly. Developers prototype at the speed of thought.

## Getting Started

**Arrow**: Follow setup in `Arrow/` directory

**Server**: Follow setup in `Server/` directory

Open Arrow, start chatting with the AI, and watch your story build itself.

---

**Narrative design at the speed of imagination.**

MIT License - Built on Arrow by Mor. H. Golkar, extended with AI by The Narrative Penguins team.
