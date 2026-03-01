# Data Model

## Core Models

### Project

```dart
class Project {
  final String id;
  final String name;
  final int colorValue;
  final String? icon;
  final bool isCollapsed;
  final ViewMode viewMode;
  final List<TerminalSession> sessions;
  final String? defaultWorkingDir;
  final DateTime createdAt;
}

enum ViewMode { list, grid, carousel }
```

### TerminalSession

```dart
class TerminalSession {
  final String id;
  final String name;
  final String? workingDir;
  final SessionSource source;
  final bool isPinned;
  final int order;
  final DateTime createdAt;
}

sealed class SessionSource {
  factory SessionSource.local({
    String? shell,
    Map<String, String>? env,
  });

  factory SessionSource.remote({
    required String deviceFingerprint,
    required String remoteSessionId,
  });

  factory SessionSource.config();

  factory SessionSource.webPreview({
    required String deviceFingerprint,
    required int port,
    String? basePath,
  });
}
```

### LiveTerminal (Runtime-Only, Not Persisted)

```dart
class LiveTerminal {
  final String sessionId;
  final Terminal terminal;
  final Pty? pty;
  final WebSocket? webSocket;
  final TerminalMode mode;
  final TerminalStatus status;
  final int? lastExitCode;
  final bool hasUnreadOutput;
  final String? currentWorkingDir;
}

enum TerminalMode { interactive, viewOnly }

enum TerminalStatus {
  spawning,     // PTY process starting
  running,      // active and connected
  reconnecting, // remote connection lost, retrying
  closed,       // process exited normally
  error,        // process crashed or connection failed
}
```

### ClosedTab (for Restore Recently Closed)

```dart
class ClosedTab {
  final TerminalSession session;
  final String projectId;
  final DateTime closedAt;
}
```

Managed by `ProjectProvider`. Max 10 items, 60-second TTL. Keyboard shortcut: Ctrl+Shift+T.

## State Diagram: Terminal Lifecycle

```
                    ┌──────────┐
                    │ SPAWNING │
                    └────┬─────┘
                         │ PTY starts / WS connects
                         ▼
    ┌───────────────────────────────────────┐
    │              RUNNING                  │
    │                                       │
    │  Local:  PTY process alive            │
    │  Remote: WebSocket connected          │
    │                                       │
    │  ┌─────────────┐  ┌──────────────┐   │
    │  │ Interactive  │◄►│  View-Only   │   │
    │  │ (can type)   │  │ (read only)  │   │
    │  └─────────────┘  └──────────────┘   │
    └───────────┬──────────────┬────────────┘
                │              │
        process exits    connection lost
                │              │
                ▼              ▼
         ┌──────────┐  ┌──────────────┐
         │  CLOSED  │  │ RECONNECTING │
         │          │  │              │──► RUNNING (if reconnect succeeds)
         └──────────┘  │ (remote only)│──► ERROR  (if max retries exceeded)
                       └──────────────┘
                              │
                       max retries
                              │
                              ▼
                       ┌──────────┐
                       │  ERROR   │
                       └──────────┘

From any state → user closes tab → resources cleaned up
```

## Persistence Schema

All persisted via SharedPreferences as JSON strings.

### Projects

```json
// Key: "xc_projects"
[
  {
    "id": "proj-001",
    "name": "Clouseau",
    "colorValue": 4280391411,
    "icon": null,
    "isCollapsed": false,
    "viewMode": "list",
    "defaultWorkingDir": "/Users/ivan/Clouseau",
    "createdAt": "2026-02-26T10:00:00Z",
    "sessions": [
      {
        "id": "sess-001",
        "name": "zsh",
        "workingDir": "/Users/ivan/Clouseau",
        "source": { "type": "local", "shell": null, "env": null },
        "isPinned": false,
        "order": 0,
        "createdAt": "2026-02-26T10:00:00Z"
      },
      {
        "id": "sess-002",
        "name": "claude",
        "workingDir": "/Users/ivan/Clouseau",
        "source": { "type": "local", "shell": null, "env": null },
        "isPinned": true,
        "order": 1,
        "createdAt": "2026-02-26T10:01:00Z"
      }
    ]
  }
]
```

### Terminal Settings

```json
// Key: "xc_terminal_settings"
{
  "defaultShell": "/bin/zsh",
  "fontSize": 14.0,
  "fontFamily": "JetBrains Mono",
  "theme": "dark",
  "cursorStyle": "block",
  "cursorBlink": true,
  "scrollbackLines": 10000,
  "allowRemoteAccess": true,
  "requirePinForTerminals": false,
  "terminalPin": null
}
```

### Active State (Restored on App Restart)

```json
// Key: "xc_active_state"
{
  "activeProjectId": "proj-001",
  "activeSessionId": "sess-002",
  "sidebarCollapsed": false
}
```

### Closed Tabs (for Restore Recently Closed)

```json
// Key: "xc_closed_tabs"
[
  {
    "session": {
      "id": "sess-003",
      "name": "logs",
      "workingDir": "/var/log",
      "source": { "type": "local", "shell": null, "env": null },
      "isPinned": false,
      "order": 2
    },
    "projectId": "proj-001",
    "closedAt": "2026-02-26T10:05:00Z"
  }
]
```

### Durable Sessions — Three-Layer Architecture

```
LAYER 1 — Tray Persistence (Phase 1, already built in LocalSend)
────────────────────────────────────────────────────────────────
Window close → app hides to tray (window_watcher.dart)
Flutter process stays alive → PTY processes survive
Scrollback intact in memory (xterm.dart Terminal objects alive)
User clicks tray icon → window reappears, everything intact

Survives: window close, minimize, sleep/wake
Fails on: explicit Cmd+Q, crash, reboot
Code needed: enable minimizeToTray: true by default

LAYER 2 — State Serialization (Phase 1, on explicit quit)
────────────────────────────────────────────────────────────────
User quits app (Cmd+Q or tray → Quit)
Save tab structure to SharedPreferences (xc_projects, xc_active_state)
PTY processes die (unavoidable without daemon)
On reopen: restore tabs, spawn fresh shells in saved workingDirs

Survives: explicit quit, reboot (tabs restored, fresh shells)
Fails on: scrollback lost

LAYER 3 — Rust PTY Daemon (Phase 2, desktop only)
────────────────────────────────────────────────────────────────
Separate Rust binary (xclouseau-daemon) manages PTY processes
Flutter app connects via Unix socket (macOS/Linux) or named pipe (Windows)
Daemon survives app quit/crash — PTY processes keep running
On reopen: reconnect to daemon, reattach to existing PTYs

Survives: app quit, app crash, reboot (with auto-start)
Resource cost: ~10-20MB daemon + normal shell process memory
Desktop only: macOS, Linux, Windows (mobile/web are viewers)

IPC protocol: length-prefixed binary over Unix socket
  SPAWN, INPUT, RESIZE, KILL, LIST, ATTACH, DETACH (client → daemon)
  OUTPUT, EXITED, SESSIONS (daemon → client)
```

### Terminal Buffer Storage (Phase 2+)

Terminal scrollback buffers are too large for SharedPreferences. Stored as files:

```
~/.xclouseau/terminal_buffers/{sessionId}.bin
```

With the daemon, buffer persistence is handled automatically — the daemon
keeps PTY processes alive, so scrollback never needs to be serialized.

Without the daemon (Layer 2 fallback), buffer serialization is a future enhancement.

### Received Files Storage

Terminal-targeted files (images, files sent to a terminal) use platform cache:
- macOS: `~/Library/Caches/xClouseau/received/`
- Linux: `~/.cache/xclouseau/received/`
- Windows: `%LOCALAPPDATA%\xClouseau\cache\received\`

Regular file transfers use LocalSend's `destination` setting (default ~/Downloads).

Auto-cleanup: terminal-targeted files older than 7 days (configurable).

## Provider Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────┐
│                     PROVIDER DEPENDENCIES                          │
│                                                                     │
│                    ┌──────────────────┐                             │
│                    │  WorkspacePage   │  (UI)                       │
│                    └────────┬─────────┘                             │
│              ┌──────────────┼──────────────┐                       │
│              ▼              ▼              ▼                        │
│    ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐          │
│    │ projectVm    │ │ terminalVm   │ │ devicesVm        │          │
│    │ Provider     │ │ Provider     │ │ Provider         │          │
│    └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘          │
│           │                │                   │                    │
│           ▼                ▼                   ▼                    │
│    ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐          │
│    │ project      │ │ terminal     │ │ nearbyDevices    │  ← FROM  │
│    │ Provider     │ │ Provider     │ │ Provider         │  LOCALSEND│
│    │              │ │              │ │                  │          │
│    │ state:       │ │ state:       │ │ state:           │          │
│    │  projects[]  │ │  terminals{} │ │  devices[]       │          │
│    │  activeProj  │ │  active id   │ │                  │          │
│    │  activeSess  │ │              │ │                  │          │
│    └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘          │
│           │                │                   │                    │
│           ▼                ▼                   ▼                    │
│    ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐          │
│    │ persistence  │ │ remote       │ │ server           │  ← FROM  │
│    │ Provider     │ │ Terminal     │ │ Provider         │  LOCALSEND│
│    │              │ │ Provider     │ │                  │          │
│    │ SharedPrefs  │ │ WebSocket    │ │ Dart HttpServer  │          │
│    │ read/write   │ │ connections  │ │ :53317 + routes  │          │
│    │              │ │              │ │ terminal routes  │  ← NEW   │
│    └──────────────┘ └──────┬───────┘ └──────────────────┘          │
│                            │                                       │
│                            ▼                                       │
│                    ┌──────────────────┐                             │
│                    │ terminal         │                             │
│                    │ Controller       │  (server-side route handler)│
│                    │                  │                             │
│                    │ listSessions()   │                             │
│                    │ attachSession()  │                             │
│                    │ handleInput()    │                             │
│                    │ handleResize()   │                             │
│                    └──────────────────┘                             │
└─────────────────────────────────────────────────────────────────────┘

Legend:
  ← FROM LOCALSEND = existing provider, we reuse it
  ← NEW            = new routes added to existing provider
  (everything else is new code)
```

## Provider Actions

### ProjectProvider

```
CreateProjectAction
  input:  name, color
  effect: adds Project with UUID, persists

DeleteProjectAction
  input:  projectId
  effect: removes project, kills all its terminals, persists

RenameProjectAction
  input:  projectId, newName
  effect: updates name, persists

AddSessionAction
  input:  projectId, name, workingDir?, source
  effect: adds TerminalSession to project, persists

RemoveSessionAction
  input:  projectId, sessionId
  effect: removes session, kills terminal if running, persists

SetActiveProjectAction
  input:  projectId
  effect: updates activeProjectId, persists

SetActiveSessionAction
  input:  sessionId
  effect: updates activeSessionId, persists

ToggleCollapseAction
  input:  projectId
  effect: toggles isCollapsed, persists

ReorderSessionAction
  input:  projectId, sessionId, newOrder
  effect: updates order field, reorders siblings, persists

PinSessionAction
  input:  projectId, sessionId
  effect: sets isPinned=true, moves to front, persists

UnpinSessionAction
  input:  projectId, sessionId
  effect: sets isPinned=false, persists

MoveSessionToProjectAction
  input:  sessionId, fromProjectId, toProjectId
  effect: removes from source, adds to target, persists

CloseTabAction
  input:  projectId, sessionId
  effect: adds to closedTabs (max 10, 60s TTL), removes session, kills terminal, persists

RestoreClosedTabAction
  input:  closedTabIndex
  effect: removes from closedTabs, adds session back to original project, persists

SetProjectViewModeAction
  input:  projectId, viewMode
  effect: updates viewMode (list/grid/carousel), persists
```

### TerminalProvider

```
SpawnTerminalAction
  input:  session (TerminalSession)
  effect: creates Terminal + Pty, wires I/O, stores in map
  fails:  if shell not found, or remote connection fails

KillTerminalAction
  input:  sessionId
  effect: kills Pty process, disposes Terminal, removes from map

ResizeTerminalAction
  input:  sessionId, cols, rows
  effect: resizes Pty + Terminal

WriteToTerminalAction
  input:  sessionId, bytes
  effect: writes bytes to Pty.write() (for pasting file paths, etc.)
```

### RemoteTerminalProvider

```
ConnectToRemoteTerminal
  input:  deviceFingerprint, remoteSessionId
  effect: opens WebSocket, creates local Terminal, wires stream

DisconnectRemoteTerminal
  input:  sessionId
  effect: closes WebSocket, disposes Terminal

SetRemoteMode
  input:  sessionId, mode (interactive/viewOnly)
  effect: sends mode control message over WebSocket

ReconnectRemoteTerminal
  input:  sessionId
  effect: attempts to re-establish WebSocket connection
```

## Model Relationships

```
User's Device
    │
    ├── Project "Clouseau"
    │   ├── TerminalSession "zsh"      ──► LiveTerminal (local PTY)
    │   ├── TerminalSession "claude"   ──► LiveTerminal (local PTY)
    │   └── TerminalSession "Mac vim"  ──► LiveTerminal (remote WS to Mac)
    │
    ├── Project "MyApp"
    │   ├── TerminalSession "dev"      ──► LiveTerminal (local PTY)
    │   ├── TerminalSession "tests"    ──► LiveTerminal (local PTY)
    │   └── TerminalSession "preview"  ──► WebView (Mac:3000 via proxy)
    │
    └── Nearby Devices (from LocalSend discovery)
        ├── Device "Mac" (fingerprint: abc123)
        │   ├── Available sessions: [zsh, vim, logs]
        │   └── Available ports: [3000, 8080]
        └── Device "Phone" (fingerprint: def456)
            └── Available sessions: [] (phone has no local terminals)
```
