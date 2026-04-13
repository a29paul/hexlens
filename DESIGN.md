# Design System — Hexlens

## Product Context
- **What this is:** Native macOS League of Legends overlay with in-game stats, timers, and champion select tools
- **Who it's for:** Mac LoL players who want what Blitz/Porofessor offer on Windows
- **Space/industry:** Gaming companion tools (Blitz, Porofessor, U.GG, OP.GG, iTero, Mobalytics)
- **Project type:** Desktop app + marketing/docs website (Next.js)

## Aesthetic Direction
- **Direction:** Industrial/Utilitarian with premium finish
- **Decoration level:** Intentional (subtle depth, surface layering, no decoration for decoration's sake)
- **Mood:** HUD meets high-end tool. Precise, confident, crafted. The feeling of a well-made instrument, not a gaming toy. The kind of thing where you notice the spacing is right before you notice anything else.
- **Reference sites:** Blitz.gg (functional but generic), iTero.gg (interesting teal accent), U.GG (stripped back navy)
- **Differentiation:** Warmer palette, typographic voice, monospace as brand element. Every competitor uses pitch black + generic sans-serif. Hexlens uses warm navy + Satoshi + JetBrains Mono. That's the gap.

## Typography
- **Display/Hero:** Satoshi (700, 800) — geometric, confident, slightly wider than category norms. Says "we care about craft" without being decorative. Load from CDN Fonts or self-host.
- **Body:** DM Sans (400, 500, 600) — clean, readable, excellent tabular-nums for stats. Not Inter. Warmer, more personality. Google Fonts.
- **UI/Labels:** DM Sans (500, 600) — uppercase tracking for section headers (10px, tracking 1.5px)
- **Data/Tables:** JetBrains Mono (400, 500) — the overlay uses monospace for timers and cooldowns. Carrying this to the website creates brand continuity. Google Fonts.
- **Code:** JetBrains Mono (400)
- **Loading:** Google Fonts CDN for web (`fonts.googleapis.com`). Native app uses SF Pro (system) + SF Mono (system monospace).
- **Scale:**
  - `hero`: 72px / 800 / -0.03em tracking
  - `h1`: 48px / 800 / -0.02em
  - `h2`: 32px / 700 / -0.02em
  - `h3`: 20px / 600
  - `body`: 16px / 400 / 1.6 line-height
  - `body-sm`: 14px / 400 / 1.5
  - `caption`: 12px / 500
  - `label`: 10px / 600 / uppercase / 1.5px tracking
  - `data`: 13px / JetBrains Mono 500 / tabular-nums
  - `data-lg`: 24px / JetBrains Mono 700

## Color
- **Approach:** Restrained (gold accent + warm neutrals, color is meaningful)
- **Primary (Gold):** `#c8aa6e` — LoL's gold. Used for CTAs, active states, brand moments. Hover: `#d4ba82`. Pressed: `#b89a5e`.
- **Primary foreground:** `#1a1a2e` (dark text on gold buttons)
- **Backgrounds:**
  - `--bg-base`: `#08081a` (deep warm navy, NOT pure black)
  - `--bg-surface`: `#12122a` (cards, panels, elevated elements)
  - `--bg-surface-hover`: `#1a1a3a` (interactive card hover)
  - `--bg-overlay`: `rgba(0, 0, 0, 0.75)` (in-game overlay)
- **Text:**
  - `--text-primary`: `#f0f0f0` (NOT pure white, slightly softer)
  - `--text-secondary`: `#888899` (descriptions, labels)
  - `--text-tertiary`: `#555566` (captions, timestamps)
  - `--text-muted`: `#333344` (disabled, decorative)
- **Borders:** `rgba(255, 255, 255, 0.06)` default, `rgba(255, 255, 255, 0.12)` hover
- **Semantic:**
  - Success/Ahead: `#4ade80`
  - Warning/Urgent: `#facc15`
  - Error/Behind: `#f87171`
  - Info: `#60a5fa`
- **Dark mode:** This IS dark mode. No light mode planned. The product is a gaming overlay, it lives in the dark.

## Spacing
- **Base unit:** 4px
- **Density:** Comfortable (not cramped like a data dashboard, not airy like a marketing site)
- **Scale:**
  - `2xs`: 2px
  - `xs`: 4px
  - `sm`: 8px
  - `md`: 16px
  - `lg`: 24px
  - `xl`: 32px
  - `2xl`: 48px
  - `3xl`: 64px
  - `4xl`: 96px
- **Section padding:** `3xl` (64px) vertical between major page sections
- **Card padding:** `md` (16px) for overlay cards, `lg` (24px) for website cards
- **Component gap:** `sm` (8px) between related items, `md` (16px) between groups

## Layout
- **Approach:** Grid-disciplined for data/feature sections, poster-style for hero
- **Grid:** 12 columns, `md` (16px) gap
- **Max content width:** 1200px (marketing), 900px (docs/install)
- **Border radius:**
  - `sm`: 4px (badges, small elements)
  - `md`: 8px (buttons, inputs)
  - `lg`: 12px (cards, panels)
  - `xl`: 16px (large containers)
  - `full`: 9999px (pills, tags)
- **Hero:** Full-bleed, centered, ambient glow behind headline. NOT a card grid.
- **Feature grid:** 3 columns on desktop, 2 on tablet, 1 on mobile. NOT centered text, left-aligned within each card.

## Motion
- **Approach:** Intentional (animations serve comprehension, not decoration)
- **Easing:**
  - Enter: `ease-out` (elements arriving)
  - Exit: `ease-in` (elements leaving)
  - Move: `ease-in-out` (position changes)
  - Bounce: `cubic-bezier(0.34, 1.56, 0.64, 1)` (playful moments, rare)
- **Duration:**
  - `micro`: 100ms (hover states, toggles)
  - `short`: 200ms (overlay appear/dismiss, card hover lift)
  - `medium`: 400ms (scroll-reveal entrance, page transitions)
  - `long`: 600ms (hero entrance on load)
- **Scroll-reveal:** Fade up 20px with stagger (0.08s per item in grids)
- **Hover:** Cards lift 2px (`translateY(-2px)`) + border brightens
- **Timer pulse:** `ease-in-out` 0.8s infinite, opacity 1 to 0.4 (urgent timers)
- **Ambient glow:** Radial gradient behind hero, subtle and static (no animation)

## Brand Elements
- **Monospace as identity:** JetBrains Mono is not just for code. Use it for data, stats, timer displays, version numbers, and terminal-style install instructions. This creates visual continuity between the overlay app and the website.
- **Gold as rare and meaningful:** Gold is the only color accent. It appears on CTAs, active nav items, and the logo. Everything else is neutral. When gold appears, it means "this is the action" or "this is Hexlens."
- **Warm over cold:** The deep navy (#08081a) is warmer than the category standard (pure black). This subtle warmth makes the product feel premium without being obvious. Maintain this warmth in all surface colors.

## Anti-Patterns (never do these)
- Pure black backgrounds (#000000). Always use warm navy.
- Inter, Roboto, or system-ui as primary fonts.
- Purple/violet gradient accents.
- 3-column icon-in-circle feature grids with centered text.
- Uniform border-radius on everything.
- Decorative blobs, waves, or floating shapes.
- "Built for gamers" / "Unlock your potential" marketing copy.
- Neon glow effects on text or borders.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-12 | Initial design system | Created by /design-consultation. Competitive research on Blitz, U.GG, iTero found convergence on generic dark + sans-serif. Hexlens differentiates with Satoshi, warm navy, and monospace as brand element. |
| 2026-04-12 | Satoshi over Inter | Inter is the most overused web font. Satoshi is geometric, confident, slightly wider. Says "craft" without being decorative. |
| 2026-04-12 | Warm navy (#08081a) over pure black | Every competitor uses pitch black. Warm navy is subtler, more premium. The warmth is the differentiator you feel before you name it. |
| 2026-04-12 | JetBrains Mono as brand element | The overlay app uses monospace for all data. Carrying this to the website creates continuity. Nobody else in the space does this. |
