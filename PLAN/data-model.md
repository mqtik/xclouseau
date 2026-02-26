# Data Model

## Core Models

### Project

```dart
class Project {
  final String id;           // UUID
  final String name;         // "Clouseau", "MyApp", "Blog"
  final int colorValue;      // Material color value (e.g., Colors.blue.value)
  final List<TerminalSession> sessions;
  final String? defaultWorkingDir;  // default cwd for new terminals
  final DateTime createdAt;
}
```

### TerminalSession

```dart
class TerminalSession {
  final String id;                // UUID
  final String name;              // "zsh", "claude", "build", custom name
  final String? workingDir;       // starting directory
  final SessionSource source;     // local or remote
  final DateTime createdAt;
}

sealed class SessionSource {
  // Local PTY process on this device
  factory SessionSource.local({
    String? shell,           // override default shell (e.g., "/bin/bash")
    Map<String, String>? env, // extra environment variables
  });

  // Remote terminal on another device
  factory SessionSource.remote({
    required String deviceFingerprint,  // which device
    required String remoteSessionId,    // which session on that device
  });
}
```

### LiveTerminal (Runtime-Only, Not Persisted)

```dart
class LiveTerminal {
  final String sessionId;          // maps to TerminalSession.id
  final Terminal terminal;         // xterm.dart Terminal instance
  final Pty? pty;                  // flutter_pty instance (null if remote)
  final WebSocket? webSocket;      // remote connection (null if local)
  final TerminalMode mode;        // interactive or viewOnly
  final TerminalStatus status;    // spawning, running, closed, error
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
    "defaultWorkingDir": "/Users/ivan/Clouseau",
    "createdAt": "2026-02-26T10:00:00Z",
    "sessions": [
      {
        "id": "sess-001",
        "name": "zsh",
        "workingDir": "/Users/ivan/Clouseau",
        "source": { "type": "local", "shell": null, "env": null },
        "createdAt": "2026-02-26T10:00:00Z"
      },
      {
        "id": "sess-002",
        "name": "claude",
        "workingDir": "/Users/ivan/Clouseau",
        "source": { "type": "local", "shell": null, "env": null },
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
  "viewMode": "list",
  "sidebarCollapsed": false
}
```

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
│    │ SharedPrefs  │ │ WebSocket    │ │ HTTP server      │          │
│    │ read/write   │ │ connections  │ │ file routes      │          │
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
    │   └── TerminalSession "tests"    ──► LiveTerminal (local PTY)
    │
    └── Nearby Devices (from LocalSend discovery)
        ├── Device "Mac" (fingerprint: abc123)
        │   └── Available sessions: [zsh, vim, logs]
        └── Device "Phone" (fingerprint: def456)
            └── Available sessions: [] (phone has no local terminals)
```
