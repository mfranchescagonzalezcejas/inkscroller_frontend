# Phase 6 — Visual Refresh

> **Status:** In Progress — Sprint 3 (implementation + compliance/release alignment)  
> **Depends on:** Phase 5 MVP foundation (auth, reader, backend contracts) being stable  
> **Design source of truth:** [`design/DESIGN.md`](../../design/DESIGN.md) + screen mockups under [`design/`](../../design/)

## Related diagrams

![UX/UI Flow](../diagrams/ux-ui-flow.svg)

Editable source: [`ux-ui-flow.drawio`](../diagrams/ux-ui-flow.drawio)

![Auth and Profile Flow](../diagrams/auth-profile-flow.svg)

Editable source: [`auth-profile-flow.drawio`](../diagrams/auth-profile-flow.drawio)

![Reader and Offline Flow](../diagrams/reader-offline-flow.svg)

Editable source: [`reader-offline-flow.drawio`](../diagrams/reader-offline-flow.drawio)

> **Sprint 3 status note (2026-04-08):** Phase 6 is now actively executing. Delivery is coordinated with Control Tower P0/P1 compliance and release-readiness checkpoints; status mirrors must stay synchronized across repo docs and Obsidian.

---

## Goal

Raise the visual quality of InkScroller with a cinematic, editorial-grade interface that makes the app feel like a premium digital archive — not a generic reader app. The visual language is already designed; Phase 6 translates that design into production UI.

---

## Why This Phase Exists

- Phases 1–4 built the architectural foundation and verified quality.
- Phase 5 makes the app user-aware (auth, reading preferences, adaptive reader). During Phase 5, visual work is explicitly deferred.
- Phase 6 unlocks the visual redesign once behavior and backend contracts are proven — ensuring the visual layer does not carry the cost of behavioral instability underneath it.

---

## Visual Principles (from `design/DESIGN.md`)

These principles are authoritative and non-negotiable for Phase 6 implementation:

| Principle | Description |
|-----------|-------------|
| **Editorial Immersion** | The artwork is the protagonist; the UI is the theater. Move away from "app-like" density. |
| **Intentional Asymmetry** | Break rigid verticality with large-scale typography and overlapping elements. |
| **Tonal Layering** | Hierarchy through surface shifts and negative space, not 1px borders. |
| **Glassmorphism** | Floating nav and modals use 75% opacity + 20px backdrop blur. |
| **The No-Line Rule** | No 1px solid borders. Containment via surface shifts and spacing. |
| **Brand Gradient Reserve** | Gradient is reserved for rare approved brand moments. Phase 6 button fills use Primary `#80D5CB`, not gradient or Primary Deep. |

**Color palette core:**
- Void (base canvas): `#080F10`
- Stage (primary bg): `#0D1516`
- Card: `#1A2122`
- Floating: `#333A3C`
- Primary: `#80D5CB` (teal)
- Typography: Plus Jakarta Sans

---

## Scope

### MVP — Phase 6 Foundation

The minimum viable visual refresh. Every screen must satisfy the design principles above.

1. **Home screen redesign**
   - Cinematic hero carousel with full-bleed artwork and gradient overlay
   - Floating bottom nav with glassmorphism (56px, 20px radius, 16px margins)
   - Horizontal "Continue Reading" scroll with progress bars
   - "Trending Now" grid using Hero Cards (16px radius, color-sampled glow shadow)
   - "New Chapters" list rows on `surface-container-low` without dividers
   - Category chips (pill shape, `primary` active + `surface-container-high` inactive)
   - Top bar: sticky, glazsmorphism, brand gradient logo, avatar

2. **Explore screen redesign**
   - Editorial header ("Discover your next story")
   - Search input: `surface-container-highest`, tonal focus shift (no border change)
   - Recent Searches as pill chips
   - Numbered trending list (italic large numerals as decorative element)
   - Genre grid: 2-column, each card is a gradient tile with ambient glow

3. **Library screen redesign**
   - Visual hierarchy aligned with design system
   - Hero Cards for saved titles with glow shadow
   - Clear empty-state treatment using spacing, not placeholder lines

4. **Title Detail screen redesign**
   - Full-bleed cover art with tonal gradient overlay
   - Display-scale title typography (Bold 700)
   - Primary "Read Now" action with secondary actions kept visually quieter
   - Metadata using secondary text color hierarchy
   - Official availability section before reading actions so users can support official releases when available
   - Per-title manga settings entry for reading mode and chapter language
   - Active chapter language and reader mode visible near the chapter header
   - Chapter list without dividers
   - External chapter rows clearly open official/external links instead of the internal reader
   - Compact community teaser with an expanded comments state

5. **Reader Settings screen redesign**
   - Settings panel using glassmorphism overlay
   - Surface-tier backgrounds for options sections
   - Mode toggle components using brand tokens

6. **Profile screen redesign**
   - Logged-in Profile remains the visual reference for avatar rhythm and card hierarchy
   - Guest Profile acts as a public account/app hub, not an auth redirect dead end
   - Guest Profile exposes local/device preferences in design: reader mode, app language, manga reading language
   - Settings and About stay accessible from Profile; do not add Settings to the bottom navbar
   - Surface hierarchy for reading preferences, app settings, and account actions

7. **Settings, About, and runtime state redesign**
   - Settings uses an App control center model: environment info, cache TTL chips, and a separated danger action
   - About is the legal/compliance hub: no-affiliation notices, copyright ownership, API credits, Railway and Firebase Auth
   - Runtime boards cover loading, empty, error, and offline/fallback states
   - Offline/fallback states distinguish cached content, no cache, external chapters, stale catalogue data, and partial detail/chapter failures

### V1 — Phase 6 Expansion

- Micro-animations and transitions between screens (hero exit/entrance)
- Skeleton loading states that match the visual language
- Cover "glow shadow" using dominant color sampling
- Extended genre/mood theming (dark, high-contrast, reader-mode palettes)
- Onboarding flow visual treatment

### Later / Post Phase 6

- Full dark/light mode duality with complete token set
- Accessibility refinements (contrast ratios, focus indicators)
- Tablet and large-screen layout breakpoints

---

## Feature Descriptions by Screen

### Home Screen

The home screen establishes the cinematic tone immediately. The hero section is a full-height carousel (540px) with full-bleed manga cover art, gradient fade to the Void background, and overlaid title/metadata in the lower-left. The "Read Now" CTA uses solid Primary for consistency with the Phase 6 button system. Category chips provide horizontal navigation below the hero. "Continue Reading" is a horizontal scroll of 140px-wide cards with an inline progress bar at the card bottom. "Trending Now" uses a 2-column grid of Hero Cards with rating badges. "New Chapters" is a compact list of rows with a teal dot for new-chapter indicators.

### Explore Screen

The Explore screen opens with an editorial header in display typography, not a functional header. The search input tonal focus transition (background deepens on focus, no border) is a key design moment. The trending list uses large italic numerals as visual elements. Genre tiles use unique gradient pairs per category with ambient glow blobs.

### Library Screen

The Library is the user's personal archive. It prioritizes the cover art experience over metadata density. Hero Cards dominate. Sorting/filtering controls appear as the same pill chips used in Explore.

### Title Detail Screen

This screen is the transition between browsing and reading. It should answer four questions in order: what is this work, where can I support it officially, how do I read it in InkScroller, and what is the community saying?

The cover art should feel immersive, not thumbnail-sized. Official availability appears before the read action because InkScroller may show readable MangaDex-hosted chapters and external-only chapters. The read action remains primary, but secondary actions such as download/share must stay quieter and may sit beside it.

Chapter settings are contextual to this manga. The main screen shows the active language and reader mode near the chapter header, while the tune/settings action opens a per-title settings sheet for reading mode and chapter language. Chapter rows must show at least two states: readable in-app and external-link chapters. External chapters must make it clear that they open the external/official source, not the internal reader.

Community discussion is secondary to reading. The detail screen shows only a compact teaser and a "View all" path; expanded comments live in a separate state/board.

The chapter list must not use dividers — spacing and surface color create separation.

### Reader Settings Screen

The settings panel floats over the reader canvas in a glassmorphism panel. Mode options use the design token system for surfaces. There are no visible borders. The panel should feel like a temporary overlay, not a separate screen.

### Profile Screen

The Profile screen handles account information, reading preferences, and app-level access with the same surface hierarchy used across the app. Logged-in Profile is the visual reference: avatar section first, then preference cards, app settings, and account actions.

Guest Profile follows the same rhythm. It is a public account/app hub where users can sign in, adjust local preferences in the design, and access Settings/About. It must not become a separate hero-style auth marketing screen.

### Settings Screen

Settings is a utility surface, not a main navigation destination. It should remain accessible from Profile for both guest and logged-in users.

The screen groups app environment and cache maintenance into large no-divider cards. Destructive cache clearing is visually separated and uses Danger Coral.

### About Screen

About carries the legal and attribution burden for external sources so product screens remain clean. It must include no-affiliation guidance for MangaDex and MyAnimeList/Jikan, content copyright ownership, and API/infrastructure credits.

The current design credit for backend infrastructure is **Railway**.

### Runtime and Offline/Fallback States

Runtime states are first-class design artifacts. Generic error screens are not enough.

The Pencil source includes dedicated boards for loading, empty, error, and offline/fallback states. Offline/fallback states must preserve user context whenever possible:

- cached reader pages remain readable with an offline cue;
- empty cache tells the user to reconnect without implying data loss;
- external chapters open the original source, not the internal reader;
- partial data keeps loaded metadata visible and only replaces the failed section.

---

## Out of Scope

- Backend feature work (belongs to Phase 5)
- Auth changes or session management UI (Phase 5)
- New reader behavior modes (Phase 5)
- Performance / architecture changes
- Content personalization or recommendation algorithms
- Push notifications

---

## Dependencies

| Dependency | Required for Phase 6 Start |
|-----------|---------------------------|
| Phase 5 MVP foundation (auth, UserProfile, reader modes) | Preferred — Phase 6 should not carry unstable behavior underneath |
| Design tokens implemented as Flutter ThemeData/AppTheme | Yes — tokens are the bridge between design system and code |
| Flutter widget tree using the existing Clean Architecture structure | Yes — Phase 6 is a presentation layer change only |

---

## Recommended Delivery Order

1. Establish design token constants (`AppColors`, `AppTypography`, `AppSpacing`, `AppLayout`) from `design/DESIGN.md`
2. Implement shared components: Floating Bottom Nav, Hero Card, Chapter Row, Pill Chip
3. Redesign Home screen (highest visual impact)
4. Redesign Title Detail (critical user journey)
5. Redesign Explore
6. Redesign Library
7. Redesign Reader Settings panel
8. Redesign Profile screen
9. V1 expansion (animations, skeletons, glow shadows)

---

## Design Assets

| Asset | Location | Status |
|-------|----------|--------|
| Design system document | [`design/DESIGN.md`](../../design/DESIGN.md) | ✅ Complete |
| Home screen mockup | [`design/home/`](../../design/home/) | ✅ HTML + PNG |
| Explore screen mockup | [`design/explore/`](../../design/explore/) | ✅ HTML + PNG |
| Library screen mockup | [`design/library/`](../../design/library/) | ✅ HTML + PNG |
| Title Detail mockup | [`design/title_detail/`](../../design/title_detail/) | ✅ HTML + PNG |
| Reader Settings mockup | [`design/reader_settings_open/`](../../design/reader_settings_open/) | ✅ HTML + PNG |
| Profile mockup | [`design/profile_with_theme_toggle/`](../../design/profile_with_theme_toggle/) | ✅ HTML + PNG |
| Active Pencil design board | [`design/designApp`](../../design/designApp) | ✅ Editable `.pen` source including main tabs, Profile guest, Auth, Settings, About, Reader, runtime states, Offline/Fallback, and Component Library Phase 6 |
| Nocturnal Canvas | [`design/nocturnal_canvas/DESIGN.md`](../../design/nocturnal_canvas/DESIGN.md) | Deprecated pointer to canonical `design/DESIGN.md` |

---

## Open Questions / Follow-ups

### ✅ Canonical design source resolved

`design/DESIGN.md` is the canonical design system document and `design/designApp` is the active editable Pencil source. `design/nocturnal_canvas/DESIGN.md` is deprecated and only points back to the canonical document.

### 🟡 Design token strategy

Decide whether design tokens are implemented as:
- Static Dart constants in `lib/core/design/`
- Flutter ThemeData extensions
- A generated token set from the design system

### 🟡 Animation framework choice

Phase 6 V1 requires animated transitions. Decide before implementation:
- Built-in Flutter animations vs. `flutter_animate` package vs. Rive

### 🟡 Cover glow shadow implementation

"Color-sampled glow shadow" (40% opacity of dominant cover color) requires either palette extraction from the cover image or a static fallback. Decide the implementation approach.
