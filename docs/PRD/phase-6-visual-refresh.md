# Phase 6 — Visual Refresh

> **Status:** In Progress — Sprint 3 (implementation + compliance/release alignment)  
> **Depends on:** Phase 5 MVP foundation (auth, reader, backend contracts) being stable  
> **Design source of truth:** [`design/DESIGN.md`](../../design/DESIGN.md) + screen mockups under [`design/`](../../design/)

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
| **Brand Gradient Reserve** | `linear-gradient(135deg, #0F766E, #1E40AF)` used exclusively for logo + "Start Reading" CTA. |

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
   - "Start Reading" button: brand gradient, `radius-md` (12px)
   - Metadata using secondary text color hierarchy
   - Chapter list without dividers

5. **Reader Settings screen redesign**
   - Settings panel using glassmorphism overlay
   - Surface-tier backgrounds for options sections
   - Mode toggle components using brand tokens

6. **Profile screen redesign**
   - Theme toggle integration with design token awareness
   - Surface hierarchy for settings sections
   - Stats/info layout using editorial spacing

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

The home screen establishes the cinematic tone immediately. The hero section is a full-height carousel (540px) with full-bleed manga cover art, gradient fade to the Void background, and overlaid title/metadata in the lower-left. The "Read Now" CTA uses the brand gradient. Category chips provide horizontal navigation below the hero. "Continue Reading" is a horizontal scroll of 140px-wide cards with an inline progress bar at the card bottom. "Trending Now" uses a 2-column grid of Hero Cards with rating badges. "New Chapters" is a compact list of rows with a teal dot for new-chapter indicators.

### Explore Screen

The Explore screen opens with an editorial header in display typography, not a functional header. The search input tonal focus transition (background deepens on focus, no border) is a key design moment. The trending list uses large italic numerals as visual elements. Genre tiles use unique gradient pairs per category with ambient glow blobs.

### Library Screen

The Library is the user's personal archive. It prioritizes the cover art experience over metadata density. Hero Cards dominate. Sorting/filtering controls appear as the same pill chips used in Explore.

### Title Detail Screen

This screen is the transition between browsing and reading. The cover art should feel immersive, not thumbnail-sized. The brand-gradient "Start Reading" CTA is the visual focal point. The chapter list must not use dividers — spacing and surface color create separation.

### Reader Settings Screen

The settings panel floats over the reader canvas in a glassmorphism panel. Mode options use the design token system for surfaces. There are no visible borders. The panel should feel like a temporary overlay, not a separate screen.

### Profile Screen

The Profile screen handles account information and settings with the same surface hierarchy used across the app. The theme toggle is a first-class UI element that demonstrates the design system in action.

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
| Nocturnal Canvas (duplicate) | [`design/nocturnal_canvas/DESIGN.md`](../../design/nocturnal_canvas/DESIGN.md) | ⚠️ See follow-up below |

---

## Open Questions / Follow-ups

### 🟡 Design file duplication — follow-up required

`design/DESIGN.md` and `design/nocturnal_canvas/DESIGN.md` are currently **identical**. This creates an ambiguous source of truth for the design system.

**Decision required (before Phase 6 implementation start):**
- Which file is the canonical design system source?
- Should `design/nocturnal_canvas/DESIGN.md` be removed, or does it serve a distinct purpose (e.g., a specific theme variant)?
- How should references in code or docs point to the canonical source?

**Tracking:** This is a documentation/architecture decision, not a code change. It should be resolved before any design token implementation begins.

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
