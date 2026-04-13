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

The overlay requires LoL to run in **borderless windowed** mode (not fullscreen).

## Project structure

```
hexlens/
├── desktop/          Swift macOS app
│   ├── Sources/      App, Overlay, ChampSelect, API, Models, Services
│   ├── Tests/        84 unit tests
│   └── Package.swift
├── web/              Landing page (GitHub Pages)
└── .github/          CI: tests, releases, website deploy
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
