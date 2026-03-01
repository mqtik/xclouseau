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

All terminal streaming endpoints are served by the same Dart HTTPS server that handles LocalSend file transfers (default port 53317, defined in `common/lib/constants.dart`). They inherit mTLS — the same self-signed certificate handshake protects terminal traffic.

**Important**: The current server routing (`app/lib/util/simple_server.dart`) uses exact path matching and does not support parameterized routes (`:id`) or WebSocket upgrades. Before implementing these endpoints, SimpleServer must be extended or replaced (see WP-12A in agent-work-packages.md).

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

## Scrollback / Late-Join Handling

When a viewer attaches to a session that's already running, it misses all prior output. The viewer starts with an empty terminal and only sees new output from that point forward.

```
Mitigation options (implement in order of priority):

1. Snapshot buffer (recommended for MVP):
   Host keeps last N bytes of PTY output in a ring buffer (e.g., 64 KB).
   On attach, send the buffered bytes before streaming live output.
   Gives the viewer a "catch-up" window.

2. Terminal state snapshot (future):
   Serialize the host's Terminal state (visible screen + cursor position)
   and send as the first message. More accurate but harder to implement.

3. Full scrollback sync (future):
   Send the entire scrollback buffer on attach. Most complete but
   bandwidth-expensive for long-running sessions.
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

## Mouse and Touch Input

xterm.dart has full mouse reporting support (X10, UTF-8, SGR, URXVT modes) and gesture handling. This applies equally to local and remote terminals.

**What xterm.dart handles natively:**
- Mouse click/drag/move reporting to programs (vim, htop, tmux, etc.)
- Touch tap, long-press (text selection), double-tap (word selection)
- Scroll wheel and touch scrolling (regular + alternate buffer)
- Mouse mode switching via escape sequences

**What we add (WP-08):**
- Regex-based URL detection over terminal buffer text (`url_detector.dart`)
- Cmd+click (desktop) or long-press (mobile) on detected URLs → action menu
- URL highlight on hover (underline styling)
- Menu options: "Open in browser" or "Open in web preview tab" (localhost URLs)

For remote terminals, mouse/touch events from the viewer are converted to escape sequences by xterm.dart and sent as input bytes over the WebSocket — same binary format as keyboard input. The host's PTY receives them identically to local mouse events.

---

## OSC 7 — Working Directory Tracking

Modern shells emit the OSC 7 escape sequence to report the current working directory:

```
\e]7;file:///Users/ivan/Clouseau\a
```

### How It Works in Streaming

```
Host terminal:
  Shell emits OSC 7 → PTY output contains escape sequence
  Host parses OSC 7 from PTY output → updates LiveTerminal.currentWorkingDir
  OSC 7 bytes are forwarded to viewer (part of normal PTY output stream)

Viewer terminal:
  Receives OSC 7 in PTY output stream
  Can parse it locally to track remote terminal's pwd

Session metadata (GET /sessions response):
  Includes currentWorkingDir for each session
  Enables: "Send file to remote terminal's pwd"
```

### Updated Session Response

```json
{
  "sessions": [
    {
      "id": "a1b2c3d4",
      "name": "zsh",
      "project": "Clouseau",
      "cols": 120,
      "rows": 40,
      "isInteractiveAllowed": true,
      "currentWorkingDir": "/Users/ivan/Clouseau",
      "createdAt": "2026-02-26T10:30:00Z"
    }
  ]
}
```

### Use Cases

1. **Local terminals**: track pwd for file copy (paste file to current dir)
2. **Remote terminals**: viewer knows remote terminal's directory for file targeting
3. **Tab display**: show abbreviated pwd in tab title (e.g., `~/Clouseau`)

### Fallback (if shell doesn't emit OSC 7)

- Linux: read `/proc/{pid}/cwd` symlink
- macOS: `lsof -p {pid} | grep cwd` or `proc_pidpath()`
- Windows: not easily available without daemon

The OSC 7 parser is implemented in `app/lib/util/osc7_parser.dart` (WP-04).

## Web Preview — Reverse Proxy for localhost

Any device can view another device's localhost web servers (dev servers, dashboards, etc.) through a reverse proxy on the host's xClouseau server. This works in all directions — phone views Mac's localhost, Mac views Windows' localhost, etc.

### Proxy Route

```
GET /api/xclouseau/v1/web/:port/*path

Examples:
  GET /api/xclouseau/v1/web/3000/           → proxies to localhost:3000/
  GET /api/xclouseau/v1/web/3000/api/users  → proxies to localhost:3000/api/users
  GET /api/xclouseau/v1/web/8080/index.html → proxies to localhost:8080/index.html
```

### WebSocket Proxy (for HMR / Hot Reload)

Dev servers use WebSocket for live reload. The proxy must handle WebSocket upgrades on proxied paths.

```
GET /api/xclouseau/v1/web/:port/_ws/*path
Upgrade: websocket

→ Proxies WebSocket connection to localhost:<port>/<path>
→ Enables Vite HMR, Next.js Fast Refresh, Webpack hot reload, etc.
```

### Available Ports Endpoint

Returns which localhost ports are currently listening on the host device.

```
GET /api/xclouseau/v1/ports

Response 200:
{
  "ports": [
    { "port": 3000, "process": "node" },
    { "port": 8080, "process": "python3" }
  ]
}
```

Port scanning runs periodically on the host, checking common dev ports (3000-3999, 4000-4999, 5000-5999, 8000-8999, etc.) for listening TCP sockets. Detected ports are included in the session list so viewers know what's available.

### Security

- Proxy routes go through the same mTLS server (:53317) — same encryption as terminal streaming
- Only localhost ports are proxied — the host never proxies to external addresses
- Host can disable web preview in settings (allowWebPreview toggle)
- PIN protection applies if configured

### Detection — Localhost URL in Terminal Output

When terminal output contains a localhost URL, xClouseau detects it and offers to open a web preview tab.

```
Patterns matched:
  http://localhost:\d+
  http://127.0.0.1:\d+
  http://0.0.0.0:\d+
  https://localhost:\d+

Framework-specific output:
  "ready in"           (Vite)
  "started server on"  (Next.js)
  "Listening on"       (Express, Flask, etc.)
  "Development server" (Django)

On detection:
  ┌──────────────────────────────────────────┐
  │  🌐 localhost:3000 detected              │
  │  [Open Preview]  [Open on Other Device]  │
  └──────────────────────────────────────────┘

  "Open Preview"         → opens WebView tab on THIS device
  "Open on Other Device" → shows device picker, opens on selected device
```

This detection reuses the same terminal output scanning pattern as AI CLI detection (WP-19).

## Implementation Files

| File | Role |
|------|------|
| `app/lib/provider/network/server/controller/terminal_controller.dart` | Server-side: routes, WebSocket handler, multi-viewer |
| `app/lib/provider/remote_terminal_provider.dart` | Client-side: WebSocket connection, reconnection |
| `app/lib/pages/tabs/terminal_tab.dart` | UI: local + remote mode, xterm.dart rendering |
| `app/lib/pages/device_terminals_page.dart` | UI: browse remote device's available sessions |
| `app/lib/util/simple_server.dart` | Routing: needs upgrade for parameterized routes + WebSocket |
| `app/lib/provider/network/server/controller/web_preview_controller.dart` | Server-side: reverse proxy for localhost ports, WebSocket proxy |
| `app/lib/pages/tabs/web_preview_tab.dart` | UI: WebView tab for previewing remote localhost |
| `app/lib/util/localhost_detector.dart` | Detection: parse terminal output for localhost URLs |
| `app/lib/util/url_detector.dart` | Detection: regex-based URL detection over terminal buffer for clickable links |
