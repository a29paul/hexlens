# Hexlens

The first League of Legends overlay for macOS.

Everything Blitz and Porofessor do. On Mac. For free.

[![Download](https://img.shields.io/badge/Download-Hexlens_for_Mac-c8aa6e?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/a29paul/hexlens/releases/latest)
[![Tests](https://github.com/a29paul/hexlens/actions/workflows/test.yml/badge.svg)](https://github.com/a29paul/hexlens/actions/workflows/test.yml)

## Install

**Option 1: Download DMG**

Go to [Releases](https://github.com/a29paul/hexlens/releases/latest), download the `.dmg`, drag to Applications.

**Option 2: Build from source**

```bash
cd desktop
swift build -c release
open .build/release/MacLeagueOverlay
```

Requires macOS 14+ and Xcode Command Line Tools.

## Features

Hold **Tab** to show the overlay (same key as LoL's scoreboard). Release to hide.

### Player Stats
- **KDA display** with level
- **CS/min** with total CS count
- **Gold/min** from item value
- **Kill participation %** (kills + assists / team kills)
- **Vision score/min**

### Gold Scoreboard
- **Per-lane gold matchups** with champion icons (your laner vs enemy laner)
- **Team total gold** with difference
- **Lane gold diff** (green = ahead, red = behind)

### Enemy Tracking (click to track)
- **Champion portraits** loaded from Riot's Data Dragon CDN
- **Summoner spell icons** (Flash, Ignite, etc.) with click-to-track cooldowns
- **Ultimate cooldown tracking** with gold "R" badge, click when enemy ults
  - Per-champion base cooldowns from **Meraki Analytics** (170+ champions, updated per patch)
  - Reduced by **ability haste** estimated from enemy's visible items
- When on cooldown: icon darkens, red countdown overlay shows seconds remaining

### Ally Tracker
- Teammate champion, level, ult readiness, alive/dead status

### Champion Select
- Build recommendations and rune import via LCU API
- Matchup info

### App Behavior
- **Menu bar app** that auto-detects LoL (no dock icon, no clutter)
- **Works in fullscreen and borderless windowed** mode
- **Tab-to-show** overlay (hold Tab = show, release = hide)
- **Click-to-track** spells and ults (same UX as Porofessor/Blitz)
- **Drag-to-reposition** overlay (toggle via menu bar)
- **First-launch onboarding** tooltip
- **Mid-game join** detection (works if you launch the app after the game starts)
- **Auto-reconnect** with exponential backoff on API failures
- **Copy Debug Info** in menu bar for bug reports

## Riot Games compliance

Hexlens is fully compliant with [Riot's Third Party Application Policy](https://support-leagueoflegends.riotgames.com/hc/en-us/articles/225266848-Third-Party-Applications). Same rules as Blitz and Porofessor:

- **No obfuscated data.** Only reads Riot's own APIs (Live Client Data API and League Client API).
- **No automation.** Spell tracking is manual (click the icon). The app never plays for you.
- **No decision-making.** Stats are informational, not "you should do X" coaching.
- **No vision or map hacks.** Shows the same data available to you in-game.
- **No ads.** Free and open source. No monetization.
- **No player tracking.** Zero telemetry, zero data collection.

> **Note:** The League Client API is [not officially supported](https://developer.riotgames.com/docs/lol) for third-party use. Riot tolerates it (every major companion app uses it) but provides no stability guarantees.

## Project structure

```
hexlens/
├── desktop/          Swift macOS app
│   ├── Sources/      App, Overlay, ChampSelect, API, Models, Services
│   ├── Tests/        84 unit tests
│   └── Package.swift
├── web/              Next.js + Tailwind + shadcn landing page (Vercel)
├── DESIGN.md         Design system (Satoshi + DM Sans + JetBrains Mono)
└── .github/          CI: tests, release DMG, code signing
```

## Contributing

```bash
git clone https://github.com/a29paul/hexlens.git
cd hexlens/desktop
swift build
swift test
```

## License

MIT

---

Hexlens is not affiliated with or endorsed by Riot Games. League of Legends is a trademark of Riot Games, Inc.
