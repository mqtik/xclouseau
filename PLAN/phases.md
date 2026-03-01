# Implementation Phases

## Roadmap Overview

```
Phase 0          Phase 1              Phase 2                Phase 3           Phase 4
Documentation    Desktop Terminal     Multi-Device           Cross-Device      Rebranding
                 + Tray Persistence   Streaming + Daemon     Features

  ┌──────┐       ┌──────────────┐     ┌────────────────┐     ┌───────────┐    ┌──────────┐
  │ PLAN/│──────►│ Sidebar      │────►│ Terminal       │────►│ Mobile    │───►│ Rename   │
  │ docs │       │ Tab bar      │     │ streaming      │     │ viewer    │    │ Icons    │
  │      │       │ Local PTY    │     │ protocol       │     │ Image→term│    │ IDs      │
  │      │       │ File transfer│     │ Host + viewer  │     │ Web prevw │    │ Configs  │
  └──────┘       │ Project model│     │ PTY daemon     │     │ File tools│    │          │
                 │ Tray persist │     │ Device browser │     │ View modes│    │          │
                 └──────────────┘     └────────────────┘     └───────────┘    └──────────┘

  ~1 day          ~3-5 days            ~3-5 days              ~2-3 days        ~1 day
```

## Phase Dependency Graph

```
Phase 0 (docs)
    │
    ▼
Phase 1 (foundation)
    │
    ├──────────────────────┐
    ▼                      ▼
Phase 2 (streaming)    Phase 4 (rebranding)
    │                  (can run in parallel)
    ▼
Phase 3 (mobile)
```

Phase 4 (rebranding) can run in parallel with Phase 2, since it touches
only platform config files — no overlap with feature code.

## Phase 0: Documentation

**Status**: COMPLETE

**Deliverable**: 9 documents in `PLAN/` directory

**Parallelizable**: Yes — all docs can be written simultaneously

## Phase 1: Foundation (Desktop Terminal) — COMPLETE

**Goal**: Desktop app with sidebar, tabs, local PTY terminals, file transfer

**Status**: COMPLETE (Batches 1-4, 2026-02-26 to 2026-02-27)
- WP-01 through WP-12A all implemented
- macOS debug build succeeds
- Default terminal auto-spawns on first launch
- Sidebar, tab bar, terminal tab, settings all wired

### Work Items

```
Step 1: Dependencies ──────────────────────────────────────── Sequential
  │     Add xterm + flutter_pty to pubspec.yaml
  │
  ▼
Step 2: Navigation restructure ────────────────────────────── Sequential
  │     home_page.dart → sidebar + workspace
  │     home_page_controller.dart → new tab enum
  │
  │     Parallel with Step 2:
  │     ┌──────────────────────────────────────────────────┐
  │     │ Step 3: Data model (project.dart)                │
  │     │ Step 4: Terminal provider                        │
  │     └──────────────────────────────────────────────────┘
  │
  ▼
Step 5: Sidebar widget ───────────────────────────────────── Parallel
Step 6: Tab bar widget ───────────────────────────────────── Parallel
  │     (both can be built simultaneously)
  │
  ▼
Step 7: Wire it together ─────────────────────────────────── Sequential
  │     main.dart + init.dart changes
  │
  ▼
Step 8: Tray persistence + state serialization ──────────── Sequential
  │     Enable minimizeToTray by default (Layer 1)
  │     Save tab structure on quit (Layer 2)
  │     Restore tabs with fresh shells on reopen
  │     OSC 7 pwd tracking for workingDir
  │
  ▼
Step 9: Relocate file transfer ───────────────────────────── Sequential
        Move send/receive into "Devices" section
```

### Acceptance Criteria

- [ ] `flutter run -d macos` launches with sidebar and terminal
- [ ] Terminal runs user's shell (bash/zsh)
- [ ] Full ANSI support (colors, cursor, vim works)
- [ ] Can create new projects
- [ ] Can add/remove terminal tabs
- [ ] Nearby devices visible in sidebar
- [ ] Can send/receive files (LocalSend functionality preserved)
- [ ] Terminal resizes correctly with window
- [ ] Close window → app goes to tray → reopen → terminals still running
- [ ] Quit app → reopen → tabs restored with fresh shells in correct dirs
- [ ] OSC 7 pwd tracking works (currentWorkingDir updated)

## Phase 2: Multi-Device Terminal Streaming + PTY Daemon — IN PROGRESS

**Goal**: Any device views/interacts with any other device's terminals

**Status**: Batches 5-8 COMPLETE. All Phase 2+3 features + polish implemented. Security hardening NEXT.

### Work Items

```
Step 9: Rust PTY daemon ─────────────────────────────────── Sequential
  │     portable-pty crate, daemon binary, IPC protocol
  │     Dart client (daemon_client.dart)
  │     Swap TerminalProvider from flutter_pty to daemon
  │     Desktop only: macOS, Linux, Windows
  │
  ▼
Step 10: Protocol definition ─────────────────────────────── Sequential
  │      API endpoints, WebSocket format
  │
  ├──────────────────────────────────────┐
  ▼                                      ▼
Step 11: Host side ──────────────────── Step 12: Client side ─── Parallel
  │     terminal_controller.dart           terminal_tab.dart
  │     server route registration          remote mode
  │                                        remote_terminal_provider
  │
  └──────────────┬───────────────────────┘
                 ▼
Step 13: Device terminal browser ─────────────────────────── Sequential
  │     device_terminals_page.dart
  │
  ▼
Step 14: View-only toggle ────────────────────────────────── Sequential
```

### Acceptance Criteria

- [ ] Device A's terminals appear when clicking Device A in sidebar
- [ ] Attaching to remote terminal shows live output
- [ ] Typing in remote terminal sends input to host
- [ ] Resize propagates from viewer to host
- [ ] Toggle view-only/interactive works
- [ ] Multiple viewers on same session works
- [ ] Connection recovers after brief network interruption
- [ ] Session close is communicated to all viewers
- [ ] Rust PTY daemon runs as separate process (desktop only)
- [ ] Quit app → reopen → all terminals still running with scrollback
- [ ] Daemon auto-exits after all terminals closed (30s grace period)

## Phase 3: Cross-Device Features + Terminal File Integration

**Goal**: Any device views remote terminals, previews remote localhost, sends images to terminals

### Work Items

```
Step 15: Mobile terminal viewer ─────────────────────────── Parallel
Step 16: Image-to-terminal pipeline ─────────────────────── Parallel
Step 17: Terminal file toolbar ──────────────────────────── Parallel
  │     (all three can be built simultaneously)
  │
  │     Step 15: xterm.dart viewer for mobile, touch input
  │     Step 16: Phone→desktop image flow, context-aware paste
  │              AI CLI mode (clipboard Cmd+V) vs normal (copy to pwd)
  │     Step 17: Reuse FilePickerOption for terminal context
  │              File/Media/Paste/Text buttons near terminal
  │
  ▼
Step 18: AI CLI detection ──────────────────────────────── Sequential
  │     Detect claude, codex, gemini, aider in PTY child process
  │     Show enhanced tab icon + image drop zone
  │
  ▼
Step 19: Web preview ──────────────────────────────────── Parallel
Step 20: View modes (grid, carousel) ───────────────────── Parallel
Step 21: Keyboard shortcuts ────────────────────────────── Parallel
  (all three can be built simultaneously)
  │
  │     Step 19: Reverse proxy for localhost ports
  │              WebView tab, localhost URL detection
  │              WebSocket proxy for HMR/hot reload
  │              Any device → any device (bidirectional)
```

### Acceptance Criteria

- [ ] Phone shows nearby devices
- [ ] Phone can view Mac's terminal sessions
- [ ] Phone can type into remote terminal via keyboard
- [ ] Pinch-to-zoom on terminal content
- [ ] Phone sends image → Mac receives → context-aware paste works
- [ ] AI CLI detected → image pasted via clipboard (Cmd+V)
- [ ] Normal terminal → file copied to pwd, filename typed
- [ ] Terminal file toolbar (File/Media/Paste/Text) works on desktop
- [ ] Web preview: phone opens Mac's localhost:3000 in a WebView tab
- [ ] Web preview: Mac opens Windows' localhost:8080 in a WebView tab
- [ ] Web preview: WebSocket proxied (HMR/hot reload works)
- [ ] Web preview: localhost URL detected in terminal output, prompt shown
- [ ] Grid view shows multiple terminals simultaneously
- [ ] Carousel view works on mobile with swipe

## Phase 4: Rebranding

**Goal**: Full rename from LocalSend to xClouseau

### Work Items

```
Step 17: Platform configs ────────────────────────────────── Parallelizable
  │     ~25 files, all independent of each other
  │     Can be split across agents by platform:
  │       Agent A: Android files
  │       Agent B: iOS files
  │       Agent C: macOS files
  │       Agent D: Windows + Linux files
  │       Agent E: Web + build scripts
  │
  ▼
Step 18: App icon ────────────────────────────────────────── Sequential
        Replace icon assets (needs icon design first)
```

### Acceptance Criteria

- [ ] App shows "xClouseau" in title bar, app switcher, dock
- [ ] Bundle ID is org.xclouseau everywhere
- [ ] Build scripts produce correctly named artifacts
- [ ] No remaining "LocalSend" references in user-visible text

## Parallelization Strategy for 20-30 Agents

```
BATCH 1 (no dependencies):
  Agent 1:  pubspec.yaml + terminal dependencies (WP-01)
  Agent 2:  Project data model (WP-02)

BATCH 2 (depends on Batch 1):
  Agent 3:  Project provider (WP-03)
  Agent 4:  Terminal provider (WP-04)
  Agent 5:  Terminal settings (WP-05)

BATCH 3 (depends on Batch 2):
  Agent 6:  DeviceSidebar widget (WP-06)
  Agent 7:  ChromeTabBar widget (WP-07)
  Agent 8:  TerminalTab widget — local mode (WP-08)
  Agent 9:  Settings tab extensions (WP-09)
  Agent 10: Navigation restructure (WP-10)

BATCH 4 (depends on Batch 3):
  Agent 11: Wire everything together (WP-11)
  Agent 12A: SimpleServer routing upgrade (WP-12A)

BATCH 5 (depends on Batch 4 — daemon + rebranding run parallel with streaming):
  Agent 12: Terminal streaming server (WP-12)
  Agent 31: Rust PTY daemon (WP-31)
  Agent 22: Android rebranding (WP-22)
  Agent 23: iOS rebranding (WP-23)
  Agent 24: macOS rebranding (WP-24)
  Agent 25: Windows + Linux rebranding (WP-25)
  Agent 26: Web + build scripts rebranding (WP-26)

BATCH 6 (depends on WP-12):
  Agent 13: Remote terminal provider (WP-13)
  Agent 14: Device terminal browser (WP-14)
  Agent 15: Remote terminal tab mode (WP-15)
  Agent 16: View-only toggle (WP-16)

BATCH 7 (Phase 3 + shortcuts):
  Agent 17: Mobile terminal viewer (WP-17)
  Agent 18: Image-to-terminal pipeline (WP-18)
  Agent 19: AI CLI detection (WP-19)
  Agent 20: View modes — grid + carousel (WP-20)
  Agent 21: Keyboard shortcuts (WP-21)
  Agent 32: Terminal file drop + pickers (WP-32)
  Agent 33: Web preview — reverse proxy + WebView tab (WP-33)

BATCH 8 (Polish):
  Agent 27: Terminal themes (WP-27)
  Agent 28: Terminal fonts (WP-28)
  Agent 29: Integration testing (WP-29)
  Agent 30: App icon (WP-30)
```

See [agent-work-packages.md](agent-work-packages.md) for detailed work package specs.

---

## Security Hardening Pass — After Batch 8

After all feature batches are complete and manually tested, a dedicated security pass before any public release. Covers: pairing-based terminal access, host approval prompts, interactive mode control, viewer identity tracking, rate limiting, input validation, transport enforcement.

See [security-hardening.md](security-hardening.md) for full plan.

---

## Phase 5: Remote Access (Off-LAN) — Future

**Goal**: Paired devices connect from anywhere (cafe, travel, different networks) — no servers, no cost.

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
Desktop   Streaming  Mobile   Rebrand   Remote

The key: all features work over LAN first.
Remote access adds a different transport (WebRTC P2P)
underneath the same API. No feature code changes needed.
```

### How It Works

1. **Pair once on LAN**: devices exchange certificate public keys via PIN verification
2. **Connect from anywhere**: WebRTC + free public STUN for NAT traversal
3. **Same API**: GET /sessions, POST /input, file transfer — all works over WebRTC tunnel
4. **Zero cost**: public STUN is free, signaling via QR code or push notifications

### Signaling (No Server Required)

- **MVP**: QR code / manual code exchange
- **Convenience**: Push notifications (Firebase free tier)
- **Optional**: community-hosted signaling relay (the existing `server/` code)

### Security

- Paired devices only (unknown fingerprints rejected)
- Same mTLS certificates used for LAN and remote
- End-to-end encrypted (STUN/signaling never sees data)

See [remote-access.md](remote-access.md) for full architecture and sequence diagrams.
