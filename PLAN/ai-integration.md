# AI CLI Integration

## Overview

xClouseau integrates with AI CLI tools through a three-layer model. The terminal IS the AI interface — we enhance the experience without replacing the tools developers already use.

```
┌─────────────────────────────────────────────────────────────────┐
│                   THREE-LAYER AI INTEGRATION                    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ LAYER 3: One-Tap CLI Setup                               │  │
│  │                                                           │  │
│  │ "claude not found. Install? [Yes]"                       │  │
│  │ Detects missing tools, offers to install them            │  │
│  │ Works for: claude, codex, gemini CLI                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ LAYER 2: Built-in Quick Chat                             │  │
│  │                                                           │  │
│  │ For users without CLI tools installed                     │  │
│  │ Settings → paste API key → use built-in /chat command    │  │
│  │ Lightweight chat powered by Claude/GPT/Gemini API        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ LAYER 1: Terminal-Native Enhancement                     │  │
│  │                                                           │  │
│  │ AI CLI runs in a normal terminal tab                     │  │
│  │ xClouseau detects it and adds enhancements:              │  │
│  │ • Image drop zone (from phone or local)                  │  │
│  │ • "Send from phone" button                               │  │
│  │ • Session persistence indicator                          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ BASE: Standard Terminal                                   │  │
│  │                                                           │  │
│  │ Full PTY: bash, zsh, vim, nvim, anything                 │  │
│  │ xterm.dart rendering, flutter_pty process                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Layer 1: Terminal-Native Enhancement

When a terminal tab is running an AI CLI tool, xClouseau detects it and shows contextual UI enhancements.

### AI CLI Detection

```
Detection Method:
  1. Check process name of the PTY child process
  2. Pattern match against known CLI tool names

Known patterns:
  ┌────────────────┬──────────────────────────────┐
  │ Tool           │ Process name patterns         │
  ├────────────────┼──────────────────────────────┤
  │ Claude Code    │ "claude", "claude-code"       │
  │ OpenAI Codex   │ "codex"                       │
  │ Gemini CLI     │ "gemini"                      │
  │ Aider          │ "aider"                       │
  │ OpenClaw       │ "openclaw"                    │
  └────────────────┴──────────────────────────────┘

Detection runs:
  • On terminal tab creation (check initial process)
  • Periodically (every 5s) to detect CLI launched after tab open
  • On PTY output pattern match (fallback)
```

### Enhanced UI When AI CLI Detected

```
┌──────────────────────────────────────────────────────────────────┐
│  ┌─────┐ ┌──────────────────┐ ┌─────┐                          │
│  │ zsh │ │ 🤖 claude        │ │  +  │                          │
│  └─────┘ └──────────────────┘ └─────┘                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  $ claude                                                        │
│                                                                  │
│  > Can you analyze this screenshot?                             │
│                                                                  │
│  Sure! Please share the image.                                  │
│                                                                  │
│  █                                                               │
│                                                                  │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────┐       │
│  │  📎 Drop image here or [Send from Phone]             │       │
│  │                                                      │       │
│  │  Recent: photo.jpg (from iPhone, 2 min ago)          │       │
│  └──────────────────────────────────────────────────────┘       │
└──────────────────────────────────────────────────────────────────┘

The image drop zone appears ONLY when an AI CLI is detected.
Otherwise, the terminal uses the full height.
```

### Image Drop Zone Behavior

```
User drops image (or receives from phone):
  1. Image saved to temp directory
  2. File path typed into PTY: Pty.write("/tmp/xclouseau/photo.jpg\n")
  3. AI CLI picks up the path (tool-dependent behavior)

For Claude Code specifically:
  Claude Code supports image paths as input
  The path gets pasted at the cursor position

For other tools:
  The path is pasted as text
  The user decides how the tool uses it
```

## Layer 2: Built-in Quick Chat

For users who don't have CLI tools installed but have API keys.

### Configuration

```
Settings → AI Integration
  ┌────────────────────────────────────────────┐
  │ AI Provider:  [Claude ▼]                   │
  │                                            │
  │ API Key:      [sk-ant-••••••••••••••••]   │
  │                                            │
  │ Model:        [claude-sonnet-4-5 ▼]        │
  │                                            │
  │ [Test Connection]  [Save]                  │
  └────────────────────────────────────────────┘

Supported providers:
  • Anthropic (Claude)
  • OpenAI (GPT/Codex)
  • Google (Gemini)

API keys stored in:
  • SharedPreferences (encrypted with device key)
  • Never transmitted to any server
  • Never leaves the device
```

### Quick Chat Tab

```
When API key is configured, user can create a "Quick Chat" tab:

  New Tab → Quick Chat (Claude)

The tab renders a lightweight chat UI inside the terminal area:

  ┌──────────────────────────────────────────────┐
  │  Quick Chat (Claude Sonnet 4.5)              │
  ├──────────────────────────────────────────────┤
  │                                              │
  │  You: How do I fix this Dart error?          │
  │                                              │
  │  Claude: The error suggests a type           │
  │  mismatch. Try casting the value:            │
  │                                              │
  │  ```dart                                     │
  │  final result = value as String;             │
  │  ```                                         │
  │                                              │
  │  ┌──────────────────────────────────┐        │
  │  │ Type a message...          [Send]│        │
  │  │ [📎 Attach]                      │        │
  │  └──────────────────────────────────┘        │
  └──────────────────────────────────────────────┘

This is NOT a terminal — it's a native chat widget.
It uses the API directly (HTTP POST to Claude/GPT/Gemini API).
Supports:
  • Markdown rendering
  • Code blocks with syntax highlighting
  • Image attachments (from phone or local)
  • Conversation history (persisted locally)
```

## Layer 3: One-Tap CLI Setup

When xClouseau detects a user trying to use an AI CLI that isn't installed:

```
Detection:
  User types "claude" → shell returns "command not found"
  xClouseau catches the error output pattern

Response:
  ┌──────────────────────────────────────────────┐
  │  "claude" is not installed.                  │
  │                                              │
  │  [Install Claude Code]  [Dismiss]            │
  │                                              │
  │  Or configure API key in Settings for        │
  │  built-in Quick Chat.                        │
  └──────────────────────────────────────────────┘

Install action:
  macOS/Linux: npm install -g @anthropic-ai/claude-code
  Windows:     npm install -g @anthropic-ai/claude-code

Similar for:
  codex:  npm install -g @openai/codex
  gemini: npm install -g @google/gemini-cli
```

## Phone-to-AI Image Pipeline

The killer feature: take a photo on your phone, it lands in your AI conversation on desktop.

### Sequence Diagram

```
PHONE                          DESKTOP
┌──────────┐                   ┌──────────────────────────────┐
│          │                   │  Terminal: claude             │
│ Camera   │                   │                              │
│  📸      │                   │  > analyze this screenshot   │
└────┬─────┘                   │                              │
     │                         │  Sure! Share the image.      │
     │ take photo              │                              │
     ▼                         │  █                           │
┌──────────┐                   └──────────────────────────────┘
│ Gallery  │                              │
│ select   │                              │
└────┬─────┘                              │
     │                                    │
     │ tap "Send to Mac"                  │
     ▼                                    │
┌──────────┐   LocalSend file transfer    │
│ LocalSend│──────────────────────────────►│
│ HTTPS    │   POST /api/localsend/v2/    │
│ upload   │   upload                     │
└──────────┘                              │
                                          ▼
                               ┌──────────────────────────────┐
                               │ Receive Controller           │
                               │ saves to /tmp/xclouseau/     │
                               │ photo_20260226_103000.jpg     │
                               └──────────┬───────────────────┘
                                          │
                                          ▼
                               ┌──────────────────────────────┐
                               │ Notification:                │
                               │ "photo.jpg received          │
                               │  from iPhone"                │
                               │                              │
                               │ [Paste to terminal] [Open]   │
                               └──────────┬───────────────────┘
                                          │ user clicks
                                          │ "Paste to terminal"
                                          ▼
                               ┌──────────────────────────────┐
                               │ Active terminal (claude):    │
                               │                              │
                               │ Pty.write(                   │
                               │   "/tmp/xclouseau/photo.jpg" │
                               │ )                            │
                               │                              │
                               │ Path appears at cursor       │
                               │ AI CLI processes the image   │
                               └──────────────────────────────┘
```

### File Routing Rules

```
When a file is received from another device:

1. Is an AI CLI detected in the active terminal?
   ├── Yes: Show "Paste to terminal" button prominently
   └── No:  Show standard "Open" / "Save As" options

2. Is the file an image?
   ├── Yes: Show thumbnail in notification
   └── No:  Show file icon + name + size

3. Auto-paste setting?
   ├── Enabled: automatically paste path to active terminal
   └── Disabled: show notification, wait for user action

Settings:
  "Auto-paste received files to active terminal": toggle
  "Only auto-paste when AI CLI is active": toggle
  "Received files directory": path picker
```

## Implementation Files

| Component | File | Phase |
|-----------|------|-------|
| AI detection logic | `app/lib/util/ai_cli_detector.dart` | Phase 3 |
| Image drop zone widget | `app/lib/widget/image_drop_zone.dart` | Phase 3 |
| Quick Chat tab | `app/lib/pages/tabs/quick_chat_tab.dart` | Future |
| Quick Chat provider | `app/lib/provider/quick_chat_provider.dart` | Future |
| CLI installer | `app/lib/util/cli_installer.dart` | Future |
| AI settings section | `app/lib/pages/tabs/settings_tab.dart` (extend) | Phase 3 |
| File-to-terminal bridge | `app/lib/provider/file_terminal_bridge.dart` | Phase 3 |

## Priority Order

```
MVP (Phase 3):
  1. Phone sends image → desktop receives → paste path to terminal
  2. AI CLI detection (show enhanced tab icon)
  3. Image drop zone on desktop

Post-MVP:
  4. Built-in Quick Chat (Layer 2)
  5. One-tap CLI install (Layer 3)
  6. Auto-paste settings
  7. Multiple AI provider support
```
