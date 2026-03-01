# Architecture

## Device Mesh Topology

xClouseau forms a peer-to-peer mesh where every device is both a server and a client. There is no central server, no accounts, and all data stays on the user's devices.

```
                          ┌─────────────────┐
                          │   Mac (Desktop)  │
                          │                  │
                          │ ┌──────────────┐ │
                          │ │ Terminal: zsh │ │
                          │ │ Terminal: claude│
                          │ │ Terminal: vim │ │
                          │ └──────────────┘ │
                          │ HTTP Server :53317│
                          └───────┬──┬────────┘
                  ┌───────────────┘  └───────────────┐
                  │ mTLS + WebSocket                  │ mTLS + WebSocket
                  │ • discover                        │ • discover
                  │ • stream terminals                │ • stream terminals
                  │ • transfer files                  │ • transfer files
                  ▼                                   ▼
      ┌──────────────────┐                ┌──────────────────┐
      │ Windows PC       │◄──────────────►│ Phone (iOS/Android)│
      │                  │  mTLS + WS     │                  │
      │ ┌──────────────┐ │                │ ┌──────────────┐ │
      │ │ Terminal: pwsh│ │                │ │ Remote viewer│ │
      │ │ Terminal: node│ │                │ │ File sender  │ │
      │ └──────────────┘ │                │ │ Camera → AI  │ │
      │ HTTP Server :53317│                │ └──────────────┘ │
      └──────────────────┘                │ HTTP Server :53317│
                                          └──────────────────┘

Each device:
  ✓ Runs an HTTPS server (mTLS, self-signed certs)
  ✓ Discovers peers via UDP multicast + HTTP scan
  ✓ Exposes its terminal sessions via API
  ✓ Can connect to any other device's terminals
  ✓ Can send/receive files to/from any device
  ✓ Streams terminal output as raw PTY bytes
  ✓ Renders remote terminals locally with xterm.dart
```

## Connection Types

```
┌──────────────────────────────────────────────────────────────┐
│                     Connection Matrix                        │
├──────────────┬─────────┬───────────┬───────────┬────────────┤
│              │ Desktop │ Desktop   │ Phone     │ Web        │
│              │ (same)  │ (other)   │           │ Browser    │
├──────────────┼─────────┼───────────┼───────────┼────────────┤
│ Local term   │ ✓ PTY   │ —         │ —         │ —          │
│ Remote term  │ —       │ ✓ WS/mTLS │ ✓ WS/mTLS│ ✓ WebRTC   │
│ Web preview  │ browser │ ✓ proxy   │ ✓ proxy  │ ✓ proxy    │
│ File send    │ ✓ HTTPS │ ✓ HTTPS   │ ✓ HTTPS  │ ✓ WebRTC   │
│ File receive │ ✓ HTTPS │ ✓ HTTPS   │ ✓ HTTPS  │ ✓ WebRTC   │
│ Discovery    │ mDNS    │ mDNS     │ mDNS     │ Signaling  │
└──────────────┴─────────┴───────────┴───────────┴────────────┘

LAN:     UDP multicast discovery → direct HTTPS connection
Off-LAN: WebRTC (STUN for NAT traversal, optional TURN relay)
Web:     WebRTC data channels + WebSocket signaling
```

## Layer Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI LAYER (Flutter)                       │
│                                                                 │
│  ┌─────────────┐  ┌───────────────┐  ┌───────────────────────┐ │
│  │ Workspace   │  │ Terminal View  │  │ Device / File         │ │
│  │ Page        │  │ (xterm.dart)   │  │ Transfer UI           │ │
│  │ • sidebar   │  │ • local PTY   │  │ • nearby devices      │ │
│  │ • tab bar   │  │ • remote WS   │  │ • send / receive      │ │
│  │ • projects  │  │ • view modes  │  │ • progress             │ │
│  └──────┬──────┘  └───────┬───────┘  └───────────┬───────────┘ │
│         │                 │                       │             │
├─────────┴─────────────────┴───────────────────────┴─────────────┤
│                      STATE LAYER (Refena)                       │
│                                                                 │
│  ┌──────────────┐ ┌────────────────┐ ┌────────────────────────┐ │
│  │ project      │ │ terminal       │ │ nearbyDevices          │ │
│  │ Provider     │ │ Provider       │ │ Provider               │ │
│  │              │ │                │ │                        │ │
│  │ projects[]   │ │ terminals{}    │ │ devices[]              │ │
│  │ active tab   │ │ PTY instances  │ │ discovery state        │ │
│  └──────┬──────┘ └───────┬────────┘ └───────────┬────────────┘ │
│         │                │                       │             │
│  ┌──────┴──────┐ ┌───────┴────────┐ ┌───────────┴────────────┐ │
│  │ persistence │ │ remote         │ │ server                 │ │
│  │ Provider    │ │ Terminal       │ │ Provider               │ │
│  │             │ │ Provider       │ │                        │ │
│  │ SharedPrefs │ │ WS connections │ │ HTTP server + routes   │ │
│  └─────────────┘ └───────┬────────┘ └───────────┬────────────┘ │
│                          │                       │             │
├──────────────────────────┴───────────────────────┴──────────────┤
│                    NETWORKING LAYER (Dart + Rust)                │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Multicast        │  │ HTTP Server  │  │ WebRTC           │  │
│  │ Discovery        │  │ (Dart)       │  │ (Rust)           │  │
│  │                  │  │              │  │                  │  │
│  │ UDP 224.0.0.167  │  │ :53317 mTLS  │  │ Data channels    │  │
│  │ + HTTP scan      │  │ file routes  │  │ Signaling WS     │  │
│  │                  │  │ term routes  │  │                  │  │
│  └──────────────────┘  └──────────────┘  └──────────────────┘  │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                      RUST CORE (FFI)                            │
│                                                                 │
│  ┌──────────┐  ┌──────────────────┐  ┌───────────────────────┐ │
│  │ crypto/  │  │ http/            │  │ webrtc/               │ │
│  │          │  │ (client only*)   │  │                       │ │
│  │ cert.rs  │  │ server/mod.rs *  │  │ signaling.rs          │ │
│  │ hash.rs  │  │ client/mod.rs    │  │ webrtc.rs             │ │
│  │ nonce.rs │  │ controller/v3.rs │  │                       │ │
│  │ token.rs │  │                  │  │                       │ │
│  └──────────┘  └──────────────────┘  └───────────────────────┘ │
│                                                                 │
│  * The Rust HTTP server (Hyper) exists but is NOT used by the   │
│    Flutter app. The production server is a Dart HttpServer       │
│    in app/lib/provider/network/server/server_provider.dart.     │
│    Rust core is used for crypto, HTTP client, and WebRTC only.  │
│                                                                 │
│  Tokio + Hyper + Rustls + ed25519-dalek + reqwest              │
├─────────────────────────────────────────────────────────────────┤
│                  PTY LAYER (Desktop Only)                        │
│                                                                 │
│  Phase 1: flutter_pty (in-process, dies with app)               │
│  Phase 2: xclouseau-daemon (separate Rust binary)               │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Phase 1: Flutter App ──► flutter_pty ──► /bin/zsh (PTY)   │ │
│  │          (all in one process, dies on quit)                │ │
│  │                                                            │ │
│  │ Phase 2: Flutter App ──► Unix socket ──► xclouseau-daemon │ │
│  │          (separate)        (IPC)         ├── /bin/zsh      │ │
│  │                                          ├── /bin/bash     │ │
│  │                                          └── claude (PTY)  │ │
│  │          (daemon survives app quit/crash)                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Daemon uses portable-pty (Rust crate) for PTY management       │
│  Desktop only: macOS, Linux, Windows                            │
│  Mobile/Web: viewer only (no local PTY)                         │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flows

### Flow 1: Local Terminal Session

```
User types in terminal
        │
        ▼
┌─────────────────┐
│  TerminalView   │  (xterm.dart widget)
│  onInput(bytes) │
└────────┬────────┘
         │ raw bytes
         ▼
┌─────────────────┐
│  flutter_pty    │  (PTY process)
│  Pty.write()    │
└────────┬────────┘
         │ to shell process (bash/zsh)
         ▼
┌─────────────────┐
│  Shell Process  │  (bash, zsh, claude, vim...)
│                 │
└────────┬────────┘
         │ output bytes (ANSI)
         ▼
┌─────────────────┐
│  flutter_pty    │
│  Pty.output     │  (stream)
└────────┬────────┘
         │ raw bytes
         ▼
┌─────────────────┐
│  Terminal       │  (xterm.dart core)
│  write(bytes)   │  processes ANSI codes
└────────┬────────┘
         │ triggers repaint
         ▼
┌─────────────────┐
│  TerminalView   │  renders via CustomPainter
│  60fps canvas   │
└─────────────────┘
```

### Flow 2: Remote Terminal Viewing

```
VIEWER DEVICE                              HOST DEVICE
                                           (running the terminal)
┌─────────────┐                            ┌─────────────┐
│ TerminalView│                            │ Pty process │
│ (xterm.dart)│                            │ (bash/claude)│
└──────┬──────┘                            └──────┬──────┘
       │ keyboard input                           │ output bytes
       ▼                                          ▼
┌─────────────┐    WebSocket (mTLS)      ┌─────────────────┐
│ Remote      │◄─────────────────────────│ Terminal        │
│ Terminal    │  PTY output bytes         │ Controller      │
│ Provider    │─────────────────────────►│ (server route)  │
│             │  keyboard input bytes     │                 │
└──────┬──────┘                          └─────────────────┘
       │
       ▼
┌─────────────┐
│ Terminal    │  (xterm.dart core)
│ write(bytes)│  renders output locally
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ TerminalView│  60fps local rendering
│ CustomPaint │
└─────────────┘

The host streams raw PTY bytes over WebSocket.
The viewer renders them locally — no video/VNC overhead.
Keyboard input travels back over the same WebSocket.
```

### Flow 3: Phone Sends Image to Desktop AI Session

```
PHONE                                      DESKTOP (Mac)
┌────────────┐                             ┌────────────────┐
│ Camera /   │                             │ Active terminal│
│ Gallery    │                             │ running claude  │
└─────┬──────┘                             └───────┬────────┘
      │ select image                               │
      ▼                                            │
┌────────────┐   LocalSend file transfer   ┌───────┴────────┐
│ Send to    │──────────────────────────►  │ Receive        │
│ Mac device │   HTTPS POST /upload        │ Controller     │
└────────────┘                             └───────┬────────┘
                                                   │ file saved
                                                   ▼
                                           ┌────────────────┐
                                           │ Notification:  │
                                           │ "photo.jpg     │
                                           │  received"     │
                                           │ [Paste path]   │
                                           └───────┬────────┘
                                                   │ user clicks
                                                   ▼
                                           ┌────────────────┐
                                           │ Pty.write(     │
                                           │  "/tmp/photo.jpg"│
                                           │ )              │
                                           └────────────────┘
                                           Path typed into the
                                           active terminal
```

### Flow 4: Device Discovery

```
Device A starts up
        │
        ├─► UDP multicast announcement ──► 224.0.0.167:53317
        │   {alias, fingerprint, port}
        │
        ├─► HTTP subnet scan ─────────────► 192.168.1.1-255:53317
        │   GET /api/localsend/v2/info       (parallel, 50 concurrent)
        │
        └─► Listen for announcements ◄───── other devices broadcasting
                                             on the same multicast group
        │
        ▼
┌─────────────────┐
│ nearbyDevices   │  Refena provider
│ Provider        │  merges all discovery methods
│                 │  deduplicates by certificate fingerprint
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Sidebar UI      │  shows discovered devices
│ "Nearby Devices"│  with alias, device type icon
└─────────────────┘
```

### Flow 5: Web Preview (Phone Views Desktop's localhost)

```
PHONE                                      MAC (running dev server on :3000)

┌────────────┐                             ┌──────────────────────────┐
│ WebView    │                             │ xClouseau server :53317  │
│ Tab        │     mTLS HTTPS              │                          │
│            │─────────────────────────────►│ /api/xclouseau/v1/      │
│ loads URL: │                             │   web/3000/*path         │
│ https://   │                             │                          │
│ <mac-ip>:  │◄─────────────────────────────│ reverse proxy to        │
│ 53317/api/ │     HTML/CSS/JS/WS          │ localhost:3000           │
│ xclouseau/ │                             │                          │
│ v1/web/    │                             └──────────┬───────────────┘
│ 3000/      │                                        │ localhost
└────────────┘                             ┌──────────▼───────────────┐
                                           │ Dev server (vite/next)   │
                                           │ localhost:3000            │
                                           └──────────────────────────┘

Detection: terminal output contains "localhost:3000"
  → xClouseau shows "Open on this device?" prompt
  → user taps → WebView tab opens with proxied URL

The proxy runs on the same mTLS server (:53317).
WebSocket connections are also proxied (for HMR/hot reload).
```

## Platform Matrix

```
┌───────────────┬────────┬─────────┬───────┬───────┬───────┬─────┐
│ Feature       │ macOS  │ Windows │ Linux │ iOS   │Android│ Web │
├───────────────┼────────┼─────────┼───────┼───────┼───────┼─────┤
│ Local PTY     │   ✓    │    ✓    │   ✓   │  ✗*   │  ✗*  │ ✗** │
│ Remote view   │   ✓    │    ✓    │   ✓   │   ✓   │   ✓  │  ✓  │
│ Remote input  │   ✓    │    ✓    │   ✓   │   ✓   │   ✓  │  ✓  │
│ Web preview   │   ✓    │    ✓    │   ✓   │   ✓   │   ✓  │  ✓  │
│ File send     │   ✓    │    ✓    │   ✓   │   ✓   │   ✓  │  ✓  │
│ File receive  │   ✓    │    ✓    │   ✓   │   ✓   │   ✓  │  ✓  │
│ LAN discovery │   ✓    │    ✓    │   ✓   │   ✓   │   ✓  │ ✗***│
│ System tray   │   ✓    │    ✓    │   ✓   │   ✗   │   ✗  │  ✗  │
│ Share ext.    │   ✓    │    ✗    │   ✗   │   ✓   │   ✓  │  ✗  │
└───────────────┴────────┴─────────┴───────┴───────┴───────┴─────┘

*   Mobile: no local PTY, but can view/interact with remote terminals
**  Web: no local PTY, uses WebRTC for remote terminal viewing
*** Web: uses signaling server for discovery instead of multicast
```

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                     Security Layers                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Transport: mutual TLS (mTLS)                        │   │
│  │ • Self-signed RSA certificates (10-year validity)   │   │
│  │ • Generated on first app start                      │   │
│  │ • Both client and server present certificates       │   │
│  │ • Rustls + Ring (no OpenSSL)                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Identity: certificate fingerprinting                │   │
│  │ • SHA-256 hash of DER certificate                   │   │
│  │ • Used to identify and deduplicate devices          │   │
│  │ • Persisted across sessions                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Freshness: nonce exchange                           │   │
│  │ • 32-byte random nonces exchanged before register   │   │
│  │ • Prevents replay attacks                           │   │
│  │ • LRU cache (200 entries) for nonce storage         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Authorization: per-transfer tokens                  │   │
│  │ • UUID token per accepted file transfer             │   │
│  │ • Terminal sessions: access controlled by host      │   │
│  │ • Optional PIN protection                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Terminal streaming inherits ALL of the above.             │
│  Remote terminal access = same mTLS channel as file        │
│  transfer, just different API endpoints.                   │
└─────────────────────────────────────────────────────────────┘
```

## How xClouseau Extends LocalSend

```
LocalSend (what we inherit):        xClouseau (what we add):
┌────────────────────────┐          ┌────────────────────────┐
│ • mTLS encryption      │          │ • Terminal emulator    │
│ • Device discovery     │  ────►   │ • Project workspaces   │
│ • File transfer        │  extend  │ • Remote terminal      │
│ • WebRTC transport     │          │   streaming protocol   │
│ • 6-platform support   │          │ • AI CLI integration   │
│ • Certificate identity │          │ • Tab/grid/carousel    │
│ • HTTP server (Dart)   │          │   view modes           │
│ • System tray/share    │          │ • Image-to-terminal    │
└────────────────────────┘          │   pipeline             │
                                    │ • Web preview (reverse │
                                    │   proxy for localhost) │
                                    └────────────────────────┘
```
