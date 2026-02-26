# Terminal Streaming Protocol

## Overview

Terminal streaming allows any xClouseau device to view and interact with terminal sessions running on another device. The host device runs the actual PTY process; the viewer device receives raw terminal output bytes and renders them locally using xterm.dart.

```
┌──────────────────┐                    ┌──────────────────┐
│   VIEWER DEVICE  │                    │   HOST DEVICE    │
│                  │                    │                  │
│  ┌────────────┐  │   WebSocket/mTLS   │  ┌────────────┐ │
│  │ xterm.dart │◄─┼────────────────────┼──│ PTY process│ │
│  │ Terminal   │  │  raw output bytes   │  │ (bash/zsh) │ │
│  │ View      │──┼────────────────────┼─►│            │ │
│  │           │  │  keyboard input      │  │            │ │
│  └────────────┘  │                    │  └────────────┘ │
└──────────────────┘                    └──────────────────┘
```

## API Endpoints

All terminal streaming endpoints are served by the same HTTPS server that handles LocalSend file transfers (default port 5030). They inherit mTLS — the same self-signed certificate handshake protects terminal traffic.

### Base Path

```
/api/xclouseau/v1
```

### List Sessions

Returns all terminal sessions available on this device.

```
GET /api/xclouseau/v1/sessions

Response 200:
{
  "sessions": [
    {
      "id": "a1b2c3d4",
      "name": "zsh",
      "project": "Clouseau",
      "cols": 120,
      "rows": 40,
      "isInteractiveAllowed": true,
      "createdAt": "2026-02-26T10:30:00Z"
    },
    {
      "id": "e5f6g7h8",
      "name": "claude",
      "project": "Clouseau",
      "cols": 120,
      "rows": 40,
      "isInteractiveAllowed": true,
      "createdAt": "2026-02-26T10:35:00Z"
    }
  ]
}
```

### Attach to Session (WebSocket Upgrade)

Establishes a bidirectional stream for terminal I/O.

```
GET /api/xclouseau/v1/sessions/:id/attach
Upgrade: websocket
Connection: Upgrade

→ Upgrades to WebSocket
→ Server streams PTY output as binary frames
→ Client sends keyboard input as binary frames
→ Control messages use JSON text frames
```

### Input to Session (HTTP Fallback)

For environments where WebSocket isn't available.

```
POST /api/xclouseau/v1/sessions/:id/input
Content-Type: application/octet-stream

Body: raw keyboard bytes

Response 200: {}
```

### Resize Session

```
POST /api/xclouseau/v1/sessions/:id/resize
Content-Type: application/json

{
  "cols": 150,
  "rows": 50
}

Response 200: {}
```

## WebSocket Message Format

Once the WebSocket connection is established on `/attach`, messages flow in both directions:

### Binary Frames (Terminal Data)

```
Direction: Host → Viewer
Content:   Raw PTY output bytes (includes ANSI escape codes)
Format:    Binary WebSocket frame
Usage:     Viewer feeds bytes into xterm.dart Terminal.write()

Direction: Viewer → Host
Content:   Raw keyboard input bytes
Format:    Binary WebSocket frame
Usage:     Host writes bytes into Pty.write()
```

### Text Frames (Control Messages)

```json
// Viewer → Host: resize request
{
  "type": "resize",
  "cols": 150,
  "rows": 50
}

// Viewer → Host: mode change
{
  "type": "mode",
  "interactive": false
}

// Host → Viewer: session metadata update
{
  "type": "meta",
  "name": "claude",
  "cols": 120,
  "rows": 40
}

// Host → Viewer: session ended
{
  "type": "closed",
  "reason": "process_exited",
  "exitCode": 0
}

// Host → Viewer: error
{
  "type": "error",
  "message": "Session not found"
}
```

## Sequence Diagrams

### Attach to Remote Terminal

```
Viewer                                    Host
  │                                        │
  │  GET /sessions                         │
  │───────────────────────────────────────►│
  │◄───────────────────────────────────────│
  │  200 OK [{id, name, cols, rows}]       │
  │                                        │
  │  GET /sessions/a1b2c3d4/attach         │
  │  Upgrade: websocket                    │
  │───────────────────────────────────────►│
  │◄───────────────────────────────────────│
  │  101 Switching Protocols               │
  │                                        │
  │  ════════ WebSocket Open ════════      │
  │                                        │
  │  TEXT: {"type":"meta","cols":120,       │
  │◄──────  "rows":40,"name":"zsh"}        │
  │                                        │
  │  BIN: PTY output bytes                 │
  │◄──────────────────────────────────────│
  │  (continuous stream as terminal        │
  │   produces output)                     │
  │                                        │
  │  BIN: keyboard input bytes             │
  │───────────────────────────────────────►│
  │  (user types in viewer)                │  → Pty.write(bytes)
  │                                        │
  │  BIN: PTY response bytes               │
  │◄──────────────────────────────────────│
  │  → Terminal.write(bytes)               │
  │                                        │
```

### Resize Remote Terminal

```
Viewer                                    Host
  │                                        │
  │  TEXT: {"type":"resize",               │
  │─────── "cols":150,"rows":50}──────────►│
  │                                        │  → Pty.resize(150, 50)
  │                                        │
  │  TEXT: {"type":"meta",                 │
  │◄──────  "cols":150,"rows":50}          │
  │                                        │
  │  BIN: PTY re-renders with new size     │
  │◄──────────────────────────────────────│
  │                                        │
```

### Toggle View-Only / Interactive

```
Viewer                                    Host
  │                                        │
  │  TEXT: {"type":"mode",                 │
  │─────── "interactive":false}───────────►│
  │                                        │  Host stops accepting
  │                                        │  binary input frames
  │  BIN: keyboard input (ignored)         │  from this viewer
  │───────────────────────────────────────►│  → dropped
  │                                        │
  │  TEXT: {"type":"mode",                 │
  │─────── "interactive":true}────────────►│
  │                                        │  Host resumes accepting
  │  BIN: keyboard input (accepted)        │  binary input frames
  │───────────────────────────────────────►│  → Pty.write(bytes)
  │                                        │
```

### Session Closes

```
Viewer                                    Host
  │                                        │
  │                                        │  Shell process exits
  │                                        │  (exit code 0)
  │                                        │
  │  TEXT: {"type":"closed",               │
  │◄──────  "reason":"process_exited",     │
  │         "exitCode":0}                  │
  │                                        │
  │  ════════ WebSocket Close ════════     │
  │                                        │
  Viewer shows "Session ended" UI
  Option to reconnect or close tab
```

## Multi-Viewer Support

Multiple viewers can attach to the same terminal session simultaneously.

```
                        ┌──────────┐
                   ┌───►│ Viewer A │  (interactive)
                   │    │ Windows  │
                   │    └──────────┘
┌──────────┐       │
│  Host    │───────┤    ┌──────────┐
│  Mac     │       ├───►│ Viewer B │  (view-only)
│  PTY     │       │    │ Phone    │
└──────────┘       │    └──────────┘
                   │
                   │    ┌──────────┐
                   └───►│ Viewer C │  (interactive)
                        │ Linux    │
                        └──────────┘

Rules:
  • All viewers receive the same PTY output bytes
  • Multiple interactive viewers: input from all is written to PTY
    (like shared tmux session — "pair programming" mode)
  • Host can revoke interactive access per viewer
  • Host can disconnect viewers
```

## Security

Terminal streaming inherits the full LocalSend security stack:

```
┌─────────────────────────────────────────────┐
│ 1. Discovery: device found via UDP/HTTP     │
│ 2. TLS handshake: mutual certificate check  │
│ 3. Nonce exchange: anti-replay              │
│ 4. Device registration: exchange identities │
│ 5. Terminal attach: WebSocket over mTLS     │
│                                             │
│ All terminal bytes travel over the same     │
│ encrypted channel as file transfers.        │
│                                             │
│ Additional terminal-specific controls:      │
│ • Host can require approval for attach      │
│ • Host can set sessions as view-only        │
│ • Host can set PIN for terminal access      │
│ • Host can disconnect viewers at any time   │
└─────────────────────────────────────────────┘
```

## Bandwidth Considerations

```
Terminal output is text-based — very lightweight compared to
file transfer or screen sharing.

Typical bandwidth:
  Idle terminal:           ~0 bytes/sec
  Active coding:           ~1-5 KB/sec
  Scrolling build output:  ~50-200 KB/sec
  cat large-file.txt:      ~1-10 MB/sec (burst)

For comparison:
  VNC screen share:        ~1-5 MB/sec continuous
  Video call:              ~2-8 MB/sec continuous

Terminal streaming is 10-100x more bandwidth-efficient
than screen sharing for the same use case.
```

## Implementation Files

| File | Role |
|------|------|
| `app/lib/provider/network/server/controller/terminal_controller.dart` | Server-side: routes, WebSocket handler, multi-viewer |
| `app/lib/provider/remote_terminal_provider.dart` | Client-side: WebSocket connection, reconnection |
| `app/lib/pages/tabs/terminal_tab.dart` | UI: local + remote mode, xterm.dart rendering |
| `app/lib/pages/device_terminals_page.dart` | UI: browse remote device's available sessions |
| `core/src/http/server/controller/v3.rs` | Rust: if terminal routes need to be in Rust core |
