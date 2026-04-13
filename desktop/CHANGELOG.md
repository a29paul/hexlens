# Changelog

All notable changes to Hexlens will be documented in this file.

## [0.1.0.0] - 2026-04-12

### Added
- Native macOS menu bar app with automatic LoL process detection
- Transparent in-game overlay with CS tracker, jungle timers, and enemy summoner spell tracking
- Champion select panel with build recommendations and matchup info
- Rune auto-import via LCU API (one-click rune setup during champ select)
- Global hotkey spell tracking (F1-F10) with cooldown timers and debounce
- Role-adaptive CS benchmarks (jungle, support, ADC, mid, top)
- DataDragon integration for champion and spell data, cached per patch
- Meraki Analytics integration for build/rune recommendations
- Drag-to-reposition overlay with position persistence across sessions
- First-launch onboarding tooltip (hotkeys, borderless windowed requirement)
- Settings: overlay opacity slider, LoL install path configuration
- Copy Debug Info for bug reports
- 84 unit tests across 6 test suites

### Fixed
- Timer leak when Live Client Data API polling enters backoff
- Enemy spell list showing all 10 players instead of 5 enemies
- Rift Herald kill overwriting Baron Nashor timer
- Overlay not hiding when LoL loses focus
- URLSession leak on every rune import call
- SSL certificate bypass accepting any localhost port (now scoped to LCU port only)
