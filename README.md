# Hexlens

The first League of Legends overlay for macOS.

CS tracker, jungle timers, spell tracking, rune import. Native Swift. Zero Overwolf.

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

## What it does

- **In-game overlay** with CS tracker, jungle timers, and enemy spell tracking
- **Champion select panel** with build recommendations and one-click rune import
- **Menu bar app** that auto-detects LoL and shows game state
- **Global hotkeys** (F1-F10) to mark enemy summoner spell cooldowns
- **Role-adaptive benchmarks** (jungler gets jungle CS, support gets ward score)

The overlay works in both **fullscreen** and **borderless windowed** mode.

## Riot Games compliance

Hexlens is fully compliant with [Riot's Third Party Application Policy](https://support-leagueoflegends.riotgames.com/hc/en-us/articles/225266848-Third-Party-Applications). It follows the same rules as approved tools like Blitz and Porofessor:

- **No obfuscated data.** Hexlens only reads data from Riot's own APIs (Live Client Data API and League Client API). It does not read game memory, inject code, or access hidden information.
- **No automation during gameplay.** Spell tracking is manual (you press a hotkey). The app never plays the game for you.
- **No decision-making.** CS benchmarks show static averages, not real-time coaching or "you should do X" prompts.
- **No vision or map hacks.** The overlay displays the same information available to you in-game.
- **No ads.** Free and open source. No monetization of any kind.
- **No player tracking.** Hexlens does not collect, store, or transmit any player data.

Rune import during champion select writes to the League Client API, the same mechanism used by Blitz, Porofessor, and U.GG.

> **Note:** The League Client API is [not officially supported](https://developer.riotgames.com/docs/lol) for third-party use. Riot tolerates it (every major companion app uses it) but provides no stability guarantees. Hexlens will never get your account banned, but API changes in a patch could temporarily break features until we update.

## Project structure

```
hexlens/
├── desktop/          Swift macOS app
│   ├── Sources/      App, Overlay, ChampSelect, API, Models, Services
│   ├── Tests/        84 unit tests
│   └── Package.swift
├── web/              Next.js landing page (Vercel)
└── .github/          CI: tests, releases
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
