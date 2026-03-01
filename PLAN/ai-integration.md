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

### Context-Aware Paste Behavior

"Pasting" a file into a terminal means different things depending on what's running:

```
File/image received → "Paste to terminal"
                              │
                     ┌────────┴──────────┐
                     │                   │
              AI CLI detected?     Normal terminal
              (claude, aider...)         │
                     │                   │
                     ▼                   ▼
              Copy image to       Copy file to terminal's
              clipboard →         current working directory
              simulate Cmd+V      (pwd), type filename
                     │                   │
                     ▼                   ▼
              Claude Code sees    $ ls
              the image via its   photo.jpg  ← it's right here
              clipboard handler   $ _
```

**AI CLI mode:**
1. Image received from phone (or dropped on terminal)
2. Copy image bytes to system clipboard
3. Simulate Cmd+V / Ctrl+V key event into the PTY
4. Claude Code picks up the image through its native clipboard paste handling

**Normal terminal mode:**
1. File/image received from phone
2. Detect terminal's current working directory (`pwd`) via OSC 7
3. Copy file to that directory using Dart File API (not shell commands)
4. Type the filename into the terminal so user sees it

**Detecting `pwd`:**
- Modern shells emit OSC 7 escape sequence: `\e]7;file:///path\a`
- Parse this from PTY output to track current directory
- Fallback: read `/proc/{pid}/cwd` (Linux) or `lsof -p {pid}` (macOS)

### Image Drop Zone Behavior

```
User drops image (or receives from phone):

  AI CLI detected:
    1. Copy image to system clipboard
    2. Simulate Cmd+V paste event into PTY
    3. AI CLI receives image through its clipboard handler

  Normal terminal:
    1. Copy file to terminal's pwd (current working directory)
    2. Type filename into PTY so user can reference it
    3. User runs: open photo.jpg, git add photo.jpg, etc.
```

### Desktop File Picker Integration

The same LocalSend file pickers (file, media, text, clipboard, folder) are reused
for terminal context. A toolbar near the terminal offers these pickers, but instead of
sending to a device, they paste into the active terminal.

```
Terminal toolbar (visible on all terminals, not just AI CLI):
  ┌─────────────────────────────────────────────┐
  │  [File] [Media] [Paste] [Text]              │
  └─────────────────────────────────────────────┘

  file   → pick file → copy to pwd or paste path
  media  → pick image → copy to pwd (normal) or clipboard paste (AI CLI)
  text   → type text → types directly into PTY
  paste  → clipboard → pastes into PTY
  folder → pick folder → paste path into PTY
```

Reuses `FilePickerOption` from `app/lib/util/native/file_picker.dart`.

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

## Phone-to-Terminal File Pipeline

The killer feature: take a photo on your phone, it lands right where you need it on desktop.

### File Storage

Two separate destinations:

```
Regular file transfer (LocalSend):      Terminal-targeted files:
  ~/Downloads/photo.jpg                   Platform cache directory
  (user's configured destination)         (app-managed, auto-cleaned)

  User manages lifecycle                  App manages lifecycle
  Permanent until user deletes            Auto-cleaned after 7 days
  Shows in Finder/Explorer                Hidden from user's folders
```

Platform cache directories:
- macOS: `~/Library/Caches/xClouseau/received/`
- Linux: `~/.cache/xclouseau/received/`
- Windows: `%LOCALAPPDATA%\xClouseau\cache\received\`

### Sequence Diagram (AI CLI Active)

```
PHONE                          DESKTOP (claude running)
┌──────────┐                   ┌──────────────────────────────┐
│ Camera   │                   │  Terminal: claude             │
│  📸      │                   │                              │
└────┬─────┘                   │  > analyze this screenshot   │
     │ take photo              │  Sure! Share the image.      │
     ▼                         │  █                           │
┌──────────┐                   └──────────────────────────────┘
│ Send to  │  LocalSend file transfer
│ Mac      │──────────────────────────────►┐
└──────────┘                               │
                                           ▼
                               ┌──────────────────────────────┐
                               │ Save to cache dir            │
                               │ Notification: photo received │
                               │                              │
                               │ [Paste to terminal] [Save]   │
                               └──────────┬───────────────────┘
                                          │ "Paste to terminal"
                                          ▼
                               ┌──────────────────────────────┐
                               │ AI CLI detected → clipboard  │
                               │ Copy image to clipboard      │
                               │ Simulate Cmd+V               │
                               │ Claude Code receives image   │
                               └──────────────────────────────┘
```

### Sequence Diagram (Normal Terminal)

```
PHONE                          DESKTOP (zsh, pwd=/Users/ivan/myproject)
┌──────────┐                   ┌──────────────────────────────┐
│ Send     │                   │  Terminal: zsh               │
│ photo    │  LocalSend        │  ~/myproject $               │
└────┬─────┘──────────────────►│                              │
     │                         └──────────────────────────────┘
     ▼
┌──────────────────────────────┐
│ Save to cache dir            │
│ Notification: photo received │
│                              │
│ [Paste to terminal] [Save]   │
└──────────┬───────────────────┘
           │ "Paste to terminal"
           ▼
┌──────────────────────────────┐
│ Normal terminal → copy to pwd│
│ cp cache/photo.jpg           │
│    /Users/ivan/myproject/    │
│ Type "photo.jpg" into PTY    │
│                              │
│ ~/myproject $ photo.jpg      │
│ (file is right here)         │
└──────────────────────────────┘
```

### File Routing Rules

```
When a file is received from another device:

1. Save to cache dir (terminal-targeted) or destination (regular transfer)?
   ├── If sent via "Send to terminal" on phone: cache dir
   └── If sent normally: user's configured destination (~/Downloads)

2. Show notification with context-aware options:
   ├── Active terminal has AI CLI? → [Paste to terminal] prominent
   ├── Active terminal is normal shell? → [Copy to pwd] + [Paste path]
   └── No active terminal → [Save] + [Open]

3. Auto-paste setting?
   ├── Enabled: automatically paste/copy based on context
   └── Disabled: show notification, wait for user action

Settings:
  "Auto-paste received files to active terminal": toggle
  "Only auto-paste when AI CLI is active": toggle
  "Terminal received files cleanup": 7 days (configurable)
```

## Terminal Output Detection — Localhost URLs

The same output scanning used for AI CLI detection also detects localhost URLs for web preview.

```
Terminal output scanning runs on all PTY output:

  1. AI CLI detection:  process name matches claude/codex/gemini/aider
     → show enhanced tab icon + image drop zone

  2. Localhost URL detection:  output matches http://localhost:\d+
     → show "Open Preview" prompt

Both detectors share the terminal output stream but are independent.
The localhost detector is implemented in app/lib/util/localhost_detector.dart (WP-33).
```

See [terminal-streaming.md](terminal-streaming.md) for the full web preview proxy spec.

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
| Terminal file toolbar | `app/lib/widget/terminal_file_toolbar.dart` | Phase 3 |
| PWD tracker (OSC 7) | `app/lib/util/osc7_parser.dart` | Phase 1 |
| Localhost URL detector | `app/lib/util/localhost_detector.dart` | Phase 3 |
| Web preview tab | `app/lib/pages/tabs/web_preview_tab.dart` | Phase 3 |
| Web preview proxy | `app/lib/provider/network/server/controller/web_preview_controller.dart` | Phase 3 |

## Priority Order

```
MVP (Phase 3):
  1. Phone sends image → desktop receives → paste path to terminal
  2. AI CLI detection (show enhanced tab icon)
  3. Image drop zone on desktop
  4. Web preview — any device previews any device's localhost

Post-MVP:
  5. Built-in Quick Chat (Layer 2)
  6. One-tap CLI install (Layer 3)
  7. Auto-paste settings
  8. Multiple AI provider support
```
