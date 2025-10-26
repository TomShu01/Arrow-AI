# Arrow - Visual Narrative Design Tool

> **Note:** This is a fork of the original [Arrow project](https://github.com/mhgolkar/Arrow) by Mor. H. Golkar.  
> We've extended it by integrating an **AI chat assistant** that helps you build interactive narratives using natural language.  
> All original Arrow functionality remains intact—we've added AI-powered narrative generation on top.

## How to Run

### Requirements
- **Godot Engine** (version 4.x or compatible)

### Open the Project
1. Download and install Godot Engine from [godotengine.org](https://godotengine.org/)
2. Open Godot
3. Click "Import" and select the `Arrow/` folder
4. Click "Import & Edit"
5. Press F5 or click "Run" to launch Arrow

The editor will open and you can start designing interactive narratives.

---

## What Is This?

Arrow is a **visual narrative design tool** for creating interactive stories and game narratives. Think of it as a flowchart editor specifically built for storytelling—where each box (node) represents part of your story, and the connections between them create the narrative flow.

Originally created by Mor. H. Golkar, we've extended Arrow with an integrated **AI chatbot** that helps you build stories faster using natural language.

## What It Does

Arrow lets you design branching, interactive narratives visually. Instead of writing linear scripts, you create **nodes** that connect together to form complex story structures with player choices, conditional branching, character dialog, and state tracking.

### Core Concepts

#### Nodes - The Building Blocks
Every piece of your story is a node. Different node types serve different purposes:

**Content Nodes** - Narrative text without a character (scene descriptions, narration)

**Dialog Nodes** - Character speech with multiple lines that can branch to different paths

**Monolog Nodes** - Single long speech or internal thoughts by a character

**Interaction Nodes** - Action-based player choices ("Look around", "Open door", "Attack")

**Condition Nodes** - Branch the story based on variables (if health > 0, if player chose to help, etc.)

**Variable Update Nodes** - Change game state (add gold, decrease health, set flags)

**Hub Nodes** - Create choice points where multiple paths converge

**Randomizer Nodes** - Randomly select from multiple paths for variety

**Jump Nodes** - Navigate to distant parts of the story or other scenes

**Entry Nodes** - Mark where scenes begin

**Marker Nodes** - Visual labels or animation/event triggers

...and more specialized nodes for user input, character tags, sequences, etc.

#### Connections - The Flow
Nodes connect to each other to create narrative flow. When a player goes through your story, they follow these connections:
- Simple nodes have one output → one path forward
- Choice nodes (dialog, interaction) have multiple outputs → branching paths
- Condition nodes have two outputs → true/false branches

#### Characters
Define the characters in your story with names, colors, and properties. Dialog and monolog nodes are attached to specific characters.

#### Variables
Track game state with variables:
- **Numbers** - health, gold, karma scores
- **Strings** - player name, quest status
- **Booleans** - flags for events (has_key, knows_secret)

#### Scenes
Organize your story into scenes (chapters, locations, etc.). Each scene is its own graph of connected nodes.

### The AI Chatbot Integration

This is where our extension comes in. We've added an **AI assistant** directly into Arrow that understands your narrative and can build it for you.

#### How to Use It
1. Open the chat panel in Arrow
2. Type what you want: "Create a merchant who sells potions with choices to buy or leave"
3. The AI analyzes your request
4. It creates all the necessary nodes (character, dialog, interaction, connections)
5. Watch your story graph update in real-time
6. Customize the generated content as needed

#### What the AI Can Do

**Create Narrative Content**
- "Add a dialog where Elena asks about the artifact"
- "Create a scene description for the dark forest"
- "Add a character introduction for Marcus the blacksmith"

**Build Branching Logic**
- "Create a choice between helping or ignoring the stranger"
- "Add a health check that leads to game over if health is 0"
- "Make a randomizer that picks between 3 different encounters"

**Manage Resources**
- "Create a character named Sarah with blue color"
- "Add a variable called player_gold starting at 100"
- "Update the karma variable when the player chooses to help"

**Complex Sequences**
- "Build a merchant interaction with buy/sell/leave options"
- "Create a puzzle where the player must answer 'tree' to continue"
- "Add a combat system with health tracking and game over"

**Context-Aware Edits**
- Select nodes in the editor, then: "Connect these to the ending"
- "Change the selected dialog to talk about the weather"
- "Add a branch from here to a new scene"

The AI maintains full awareness of:
- Your existing characters and variables
- The current story structure
- Which nodes you have selected
- The current scene you're working in

### Visual Editor Features

**Node-Based Interface**
- Drag and drop nodes
- Visual connection wires
- Zoom and pan the canvas
- Inspector panel for editing node properties
- Console for testing narrative flow

**Project Organization**
- Multiple scenes per project
- Scene navigation
- Resource management (characters, variables)
- Macros for reusable content

**Export & Integration**
- Export to HTML (playable web version)
- Export to CSV for translation
- VCS-friendly file format (works well with git)
- Runtime integration for games

**Multi-Language Support**
- Unicode support (RTL, CJK, CTL)
- Built-in translation system
- International character handling

### Workflow Example

**Traditional Approach:**
1. Create merchant character → click through menus
2. Create dialog node → set character → write text
3. Create interaction node → add 3 options → set labels
4. Create 3 outcome content nodes → write outcomes
5. Manually wire 7+ connections between nodes
6. Test in console, fix connection mistakes

Time: 5-10 minutes

**With AI Chatbot:**
1. Type: "Create a merchant offering health potions with buy/decline options"
2. AI creates: merchant character, dialog, interaction, outcomes, connections
3. Customize the generated content if desired

Time: 10 seconds + customization

### How It Works Behind the Scenes

When you use the AI chatbot:

1. **You send a message** through Arrow's chat UI
2. **Arrow sends** your message + full project context to the AI server via WebSocket
3. **Server processes** your request through multi-agent system
4. **Server sends back function calls** like `create_dialog_node(...)`
5. **Arrow executes** the functions, creating actual nodes in your project
6. **Arrow sends results** back to server (success/failure, new IDs)
7. **Server continues** with next steps using those results
8. **You see updates** in real-time as nodes appear and connect

The AI doesn't just generate text—it generates valid narrative structures that work in Arrow.

## Technology

**Game Engine**: Godot (GDScript)  
**UI**: Custom node-based visual editor  
**Communication**: WebSocket client for AI server connection  
**File Format**: JSON-based, VCS-friendly  
**Export**: HTML/JS runtime included  

## Project Structure

```
Arrow/
├── main.tscn                   # Main editor scene
├── project.godot               # Godot project config
├── nodes/                      # Node type definitions
│   ├── dialog/                 # Dialog node implementation
│   ├── content/                # Content node implementation
│   ├── condition/              # Condition node implementation
│   └── ...                     # Other node types
├── scripts/
│   ├── core/                   # Core narrative engine
│   ├── editor/                 # Editor UI logic
│   ├── shared/                 # Shared utilities
│   └── main.gd                 # Entry point
├── assets/                     # Icons, themes, fonts
├── runtimes/
│   └── html-js/                # HTML export runtime
└── projects/                   # Example projects
```

## Key Features

- **100% Visual Development** - No coding required for basic narratives
- **AI-Powered Creation** - Natural language to narrative structures
- **Advanced Node System** - Rich palette of narrative tools
- **Real-time Collaboration** - Work with AI as a co-designer
- **Branching Narratives** - Complex choice-based stories
- **State Management** - Variables, tags, and conditional logic
- **Character System** - Full character and dialog management
- **Export Ready** - One-click playable HTML export
- **Open Source** - Free and extensible

## Use Cases

- **Game Narrative Design** - Create dialog trees and quest systems for games
- **Interactive Fiction** - Build text-adventure games and visual novels
- **Prototyping** - Rapidly test narrative ideas and player choices
- **Education** - Teach interactive storytelling concepts
- **Writing** - Outline and structure complex branching narratives

Arrow bridges the gap between creative writing and technical implementation, and with the AI integration, it becomes as simple as describing your story vision.
