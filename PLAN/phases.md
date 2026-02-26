# Implementation Phases

## Roadmap Overview

```
Phase 0          Phase 1              Phase 2                Phase 3           Phase 4
Documentation    Desktop Terminal     Multi-Device           Mobile            Rebranding
                                      Streaming              Companion

  ┌──────┐       ┌──────────────┐     ┌────────────────┐     ┌───────────┐    ┌──────────┐
  │ PLAN/│──────►│ Sidebar      │────►│ Terminal       │────►│ Mobile    │───►│ Rename   │
  │ docs │       │ Tab bar      │     │ streaming      │     │ viewer    │    │ Icons    │
  │      │       │ Local PTY    │     │ protocol       │     │ Image→term│    │ IDs      │
  │      │       │ File transfer│     │ Host + viewer  │     │ View modes│    │ Configs  │
  └──────┘       │ Project model│     │ Device browser │     │           │    │          │
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

**Status**: This document and its siblings

**Deliverable**: 9 documents in `PLAN/` directory

**Parallelizable**: Yes — all docs can be written simultaneously

## Phase 1: Foundation (Desktop Terminal)

**Goal**: Desktop app with sidebar, tabs, local PTY terminals, file transfer

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
Step 8: Relocate file transfer ────────────────────────────── Sequential
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

## Phase 2: Multi-Device Terminal Streaming

**Goal**: Any device views/interacts with any other device's terminals

### Work Items

```
Step 9: Protocol definition ──────────────────────────────── Sequential
  │     API endpoints, WebSocket format
  │
  ├──────────────────────────────────────┐
  ▼                                      ▼
Step 10: Host side ──────────────────── Step 11: Client side ─── Parallel
  │     terminal_controller.dart           terminal_tab.dart
  │     server route registration          remote mode
  │                                        remote_terminal_provider
  │
  └──────────────┬───────────────────────┘
                 ▼
Step 12: Device terminal browser ─────────────────────────── Sequential
  │     device_terminals_page.dart
  │
  ▼
Step 13: View-only toggle ────────────────────────────────── Sequential
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

## Phase 3: Mobile Companion

**Goal**: Phone views remote terminals, sends images to desktop

### Work Items

```
Step 14: Mobile terminal viewer ──────────────────────────── Parallel
Step 15: Image-to-terminal pipeline ──────────────────────── Parallel
Step 16: View modes (grid, carousel) ─────────────────────── Parallel
  (all three can be built simultaneously)
```

### Acceptance Criteria

- [ ] Phone shows nearby devices
- [ ] Phone can view Mac's terminal sessions
- [ ] Phone can type into remote terminal via keyboard
- [ ] Pinch-to-zoom on terminal content
- [ ] Phone sends image → Mac receives → path pasteable to terminal
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
PARALLEL BATCH 1 (Phase 0 + Phase 1 foundations):
  Agent 1:  pubspec.yaml + dependency setup
  Agent 2:  Project data model + persistence
  Agent 3:  Terminal provider
  Agent 4:  Project provider
  Agent 5:  Navigation restructure (home_page)

PARALLEL BATCH 2 (Phase 1 UI):
  Agent 6:  ProjectSidebar widget
  Agent 7:  TerminalTabBar widget
  Agent 8:  TerminalTab widget (local mode)
  Agent 9:  Settings tab extensions
  Agent 10: Device section (relocate send/receive)

PARALLEL BATCH 3 (Phase 1 wiring + Phase 2 protocol):
  Agent 11: main.dart + init.dart wiring
  Agent 12: Terminal streaming protocol (Dart server routes)
  Agent 13: Remote terminal provider (client)
  Agent 14: Terminal controller (server handler)

PARALLEL BATCH 4 (Phase 2 UI + Phase 3):
  Agent 15: Remote terminal tab mode
  Agent 16: Device terminal browser page
  Agent 17: View-only toggle
  Agent 18: Mobile terminal viewer
  Agent 19: Image-to-terminal pipeline
  Agent 20: Grid view mode
  Agent 21: Carousel view mode

PARALLEL BATCH 5 (Phase 4 rebranding):
  Agent 22: Android rebranding
  Agent 23: iOS rebranding
  Agent 24: macOS rebranding
  Agent 25: Windows + Linux rebranding
  Agent 26: Web + build scripts rebranding

PARALLEL BATCH 6 (Polish):
  Agent 27: Keyboard shortcuts
  Agent 28: Terminal themes
  Agent 29: Integration testing
  Agent 30: App icon design/placement
```

See [agent-work-packages.md](agent-work-packages.md) for detailed work package specs.

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
