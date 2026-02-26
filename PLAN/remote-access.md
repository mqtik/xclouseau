# Remote Access (Off-LAN)

## The Problem

Phases 1-3 work on the local network (LAN). But developers travel — you leave home, go to a cafe, and still want to see your Mac's terminals from your phone. No servers. No subscriptions. No accounts. Plug and play.

## The Solution: Pair Once, Connect Forever

```
STEP 1: PAIRING (on same LAN, one time only)
┌──────────┐                           ┌──────────┐
│  Phone   │    same WiFi network      │   Mac    │
│          │◄─────────────────────────►│          │
│          │                           │          │
│  "Pair   │   LocalSend discovery     │  Shows   │
│   with   │   ────────────────────►   │  PIN:    │
│   Mac"   │                           │  4829    │
│          │   user enters PIN         │          │
│  [4829]  │   ────────────────────►   │  ✓ OK   │
│          │                           │          │
│          │   exchange public keys    │          │
│          │◄─────────────────────────►│          │
│          │                           │          │
│  Stores: │                           │ Stores:  │
│  Mac's   │                           │ Phone's  │
│  public  │                           │ public   │
│  key +   │                           │ key +    │
│  finger- │                           │ finger-  │
│  print   │                           │ print    │
└──────────┘                           └──────────┘

STEP 2: REMOTE CONNECTION (from anywhere, automatic)
┌──────────┐                           ┌──────────┐
│  Phone   │                           │   Mac    │
│ (cafe)   │    public internet        │ (home)   │
│          │                           │          │
│  Connect │   WebRTC + public STUN    │  Listening│
│  to Mac  │   ────────────────────►   │  for     │
│          │                           │  paired  │
│          │   ICE candidates via      │  devices │
│          │   signaling (see below)   │          │
│          │                           │          │
│          │◄═══ P2P tunnel (encrypted)═══►      │
│          │   mTLS (same certs as LAN)│          │
│          │                           │          │
│  View    │   terminal streaming      │  Host    │
│  Mac's   │   file transfer           │  Mac's   │
│  terminals│  all over P2P tunnel     │  terminals│
└──────────┘                           └──────────┘
```

## How It Works — Zero Server Cost

### Pairing (One-Time, On LAN)

1. Both devices are on the same network
2. User initiates pairing from either device
3. A 4-6 digit PIN is shown on one device, entered on the other
4. Devices exchange their certificate public keys over mTLS
5. Both devices store the paired device's info permanently:
   - Public key / certificate fingerprint
   - Device alias
   - Device type
   - Pairing date
6. Pairing stored in SharedPreferences, survives app updates

```dart
class PairedDevice {
  final String fingerprint;       // certificate SHA-256
  final String publicKey;         // PEM-encoded public key
  final String alias;             // "Ivan's Mac"
  final DeviceType deviceType;    // desktop, mobile, etc.
  final DateTime pairedAt;
  final String? lastKnownIp;     // for LAN fast-connect
  final int? lastKnownPort;
}
```

### Remote Discovery (Off-LAN)

Since there's no central server, devices need a way to find each other. Options, from zero-cost to cheap:

```
┌─────────────────────────────────────────────────────────────────┐
│              REMOTE DISCOVERY OPTIONS                           │
│                                                                 │
│  Option A: WebRTC + Public STUN (RECOMMENDED, FREE)            │
│  ──────────────────────────────────────────────────             │
│  • Both devices connect to free public STUN server             │
│  • STUN reveals each device's public IP + port                 │
│  • Signaling exchanged via... (see signaling options)          │
│  • P2P tunnel established directly between devices             │
│  • Works for ~70-80% of NAT configurations                    │
│  • Cost: $0                                                    │
│                                                                 │
│  Option B: DHT (Distributed Hash Table)                        │
│  ──────────────────────────────────────                        │
│  • Devices publish their address to a DHT network              │
│  • Like BitTorrent peer discovery                              │
│  • Fully decentralized, no servers needed                      │
│  • More complex to implement                                   │
│  • Cost: $0                                                    │
│                                                                 │
│  Option C: User-Hosted Relay (Self-Host TURN)                  │
│  ────────────────────────────────────────────                  │
│  • For NATs that block P2P (symmetric NAT ~20% of cases)       │
│  • User can self-host a TURN relay                            │
│  • xClouseau ships with a simple TURN server binary            │
│  • Or use any standard TURN server                             │
│  • Cost: user's own hardware                                   │
│                                                                 │
│  RECOMMENDED: Start with Option A, add B and C later           │
└─────────────────────────────────────────────────────────────────┘
```

### Signaling (How Paired Devices Exchange Connection Info)

The challenge: two devices need to exchange WebRTC offers/ICE candidates to establish a P2P tunnel. Without a server, how?

```
┌─────────────────────────────────────────────────────────────────┐
│              SIGNALING OPTIONS (ZERO SERVER COST)               │
│                                                                 │
│  Option 1: QR Code / Manual Exchange (Simplest)                │
│  ──────────────────────────────────────────────                 │
│  • Mac shows QR code with its STUN-resolved address            │
│  • Phone scans QR → knows where to connect                    │
│  • Or: Mac shows a code like "abc123.xclouseau.local"          │
│  • User types it on phone                                      │
│  • Works everywhere, zero infrastructure                       │
│                                                                 │
│  Option 2: Push Notification Signaling (Free Tier)             │
│  ─────────────────────────────────────────────────              │
│  • Use Firebase Cloud Messaging (free tier: unlimited)         │
│  • Device registers FCM token during pairing                   │
│  • To connect: send signaling data via push notification       │
│  • Extremely reliable, works even when app is backgrounded     │
│  • Free for our volume                                         │
│  • Trade-off: requires Google/Apple push services              │
│                                                                 │
│  Option 3: Shared File / Cloud Sync (Clever Hack)              │
│  ────────────────────────────────────────────────               │
│  • Both devices watch a shared location (iCloud, Google Drive)  │
│  • Write signaling data to a shared file                       │
│  • Other device reads it and connects                          │
│  • Uses infrastructure user already pays for                   │
│  • No additional cost                                          │
│                                                                 │
│  Option 4: Community Signaling Server (Optional)               │
│  ───────────────────────────────────────────────                │
│  • A lightweight WebSocket relay for signaling only            │
│  • Handles ONLY connection setup (no data passes through)       │
│  • Can be self-hosted by anyone                                │
│  • The existing LocalSend server/ code is almost this          │
│  • Community can donate hosting                                │
│                                                                 │
│  RECOMMENDED: Start with Option 1 (QR code) for MVP.           │
│  Add Option 2 (push notifications) for convenience.            │
│  Offer Option 4 as optional community infrastructure.          │
└─────────────────────────────────────────────────────────────────┘
```

### Connection Flow (Remote)

```
Phone (cafe)                                Mac (home)
     │                                           │
     │  1. Phone opens xClouseau                 │
     │     sees Mac in "Paired Devices"          │
     │     (offline indicator)                   │
     │                                           │
     │  2. Phone taps "Connect to Mac"           │
     │                                           │
     │  3. STUN: resolve own public address      │
     │     ──► stun.l.google.com:19302           │
     │     ◄── "your public IP: 1.2.3.4:5678"   │
     │                                           │  3. Mac is also
     │                                           │     STUN-resolved
     │                                           │     "3.4.5.6:7890"
     │                                           │
     │  4. Exchange addresses via signaling:     │
     │     ──► QR code, push notification,       │
     │         or signaling server               │
     │     ◄── Mac's address + ICE candidates    │
     │                                           │
     │  5. WebRTC P2P tunnel established         │
     │     ◄═══════════════════════════════════► │
     │     encrypted with same mTLS certs        │
     │     as LAN connection                     │
     │                                           │
     │  6. Same protocol as LAN:                 │
     │     GET /sessions                         │
     │     GET /sessions/:id/attach (WebSocket)  │
     │     POST /upload (file transfer)          │
     │                                           │
     │  Works identically to LAN mode.           │
     │  The transport changes (WebRTC vs TCP),   │
     │  but the API layer is the same.           │
     │                                           │
```

## Security for Remote Access

```
┌─────────────────────────────────────────────────────────────────┐
│                 REMOTE SECURITY MODEL                           │
│                                                                 │
│  PAIRING (one time, on LAN):                                   │
│  ├── PIN verification (prevents wrong device)                  │
│  ├── Certificate exchange (stores public keys)                 │
│  └── Both devices record each other's fingerprint              │
│                                                                 │
│  REMOTE CONNECTION:                                             │
│  ├── WebRTC DTLS uses same certificates as mTLS                │
│  ├── Certificate fingerprint checked against paired database   │
│  ├── Reject connection if fingerprint unknown                  │
│  ├── All data encrypted end-to-end                             │
│  └── STUN/signaling server sees only connection metadata,      │
│      never the actual data                                     │
│                                                                 │
│  Result:                                                        │
│  ├── Only paired devices can connect                           │
│  ├── Even if signaling is compromised, data is encrypted       │
│  ├── No account = no password to steal                         │
│  └── Revoking access = remove device from paired list          │
└─────────────────────────────────────────────────────────────────┘
```

## Paired Devices UI

```
Sidebar:
┌────────────┐
│ PROJECTS   │
│ ...        │
├────────────┤
│ DEVICES    │
│            │
│ Nearby:    │  (LAN discovered)
│  🖥 Win PC │  ● online
│            │
│ Paired:    │  (paired but not on LAN)
│  💻 Mac    │  ○ offline  [Connect]
│  📱 iPad   │  ○ offline  [Connect]
│            │
│ [+ Pair]   │
├────────────┤
│ ⚙ Settings │
└────────────┘

When "Connect" is tapped for an offline paired device:
  1. Attempt STUN resolution
  2. Exchange signaling data
  3. Establish WebRTC tunnel
  4. Device moves to "online" status
  5. Its terminals become available
```

## Implementation Notes

### Architecture Decision: Transport Abstraction

The key to making remote work seamlessly is abstracting the transport layer:

```
┌───────────────────────────────────────────────────┐
│                 API Layer                          │
│  GET /sessions, POST /input, etc.                 │
│  (same endpoints, same protocol)                  │
├───────────────────────────────────────────────────┤
│              Transport Abstraction                │
│                                                   │
│  ┌─────────────┐  ┌──────────────┐               │
│  │ LAN (TCP)   │  │ Remote       │               │
│  │ Direct HTTP │  │ (WebRTC)     │               │
│  │ + WebSocket │  │ Data Channel │               │
│  └─────────────┘  └──────────────┘               │
│                                                   │
│  The API layer doesn't know or care which         │
│  transport is being used.                         │
└───────────────────────────────────────────────────┘

LocalSend already has this pattern with WebRTC for the web version.
We extend it to native apps for remote access.
```

### What We Already Have From LocalSend

- WebRTC implementation in `core/src/webrtc/`
- WebSocket signaling in `core/src/webrtc/signaling.rs`
- Standalone signaling server in `server/`
- Certificate-based identity system

### What We Add

- Paired device storage and management
- PIN-based pairing flow
- STUN integration for NAT traversal
- Transport abstraction layer
- Remote connection UI (Connect button, status indicators)

## Phase 5 Timeline

```
Phase 5 comes AFTER Phase 3 (mobile companion):

  Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
  Desktop   Streaming  Mobile   Rebrand   Remote

Phase 5 sub-steps:
  5a. Paired device model + storage
  5b. PIN-based pairing flow
  5c. STUN integration
  5d. Signaling (QR code MVP)
  5e. WebRTC P2P tunnel
  5f. Transport abstraction
  5g. Remote connection UI
  5h. (Future) Push notification signaling
  5i. (Future) Community signaling server
```

## Design Principle

```
BUILD LOCAL FIRST, REMOTE LATER.

All features work over LAN first.
Remote access is just a different transport for the same API.
If it works on LAN, it works remotely — because the protocol is the same.

This means:
  • Phase 1-3 code doesn't need to know about remote
  • Phase 5 adds a transport layer underneath
  • No feature code changes needed
  • Clean separation of concerns
```
