# Arrow-AI

Arrow-AI extends the Arrow project — a visual Game Narrative Design Tool for the Godot game engine — with AI-powered narrative generation and editing capabilities.

The AI agent maintains awareness of the narrative design state within Arrow and performs edits through tool calls. Key capabilities include:

- Creating narrative content nodes (dialog, content, monologs)
- Setting up branching logic with conditions, hubs, and randomizers
- Managing variables and character data
- Structuring scenes and narrative flow
- Referencing uploaded PDF documents for story context

## Getting Started

### Client

Run the Arrow client the same way as the original Arrow project.

### Server

Start the FastAPI server from the `Server` directory:

```bash
poetry run uvicorn Arrow_AI_Backend.main:app --reload --host 0.0.0.0 --port 8000
```

Alternatively, connect to a public server at `wss://xxx.com/`.

## License

Arrow-AI is distributed under the MIT License and includes:
- Modified code from Arrow (MIT License, Copyright © 2021 Mor. H. Golkar and contributors)
- New server-side AI components (MIT License, Copyright © 2025 Kushagra Sethi, Sina Khodaveisi, Tom Shu)

For complete licensing and attribution details, see the [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT) files.

**Important:** This is a derivative work. When redistributing, you must preserve all copyright notices from both the original Arrow project and this work.