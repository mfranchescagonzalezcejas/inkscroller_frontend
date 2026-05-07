# Design System: The Cinematic Canvas

## 1. Creative North Star

**Creative North Star: “The Silent Frame”**

InkScroller is a premium manga archive. The artwork is the protagonist; the UI is the theater around it. The interface must feel cinematic, quiet, and editorial — not dense, generic, or overly “app-like”.

The system is built on three rules:

1. **Artwork first** — covers and pages carry the emotion.
2. **Depth through tone** — surfaces, spacing, blur, and shadows create hierarchy.
3. **Teal is the brand color, not the whole palette** — teal should guide attention, not flood the UI.

---

## 2. Color System

The palette uses dark neutrals for most of the interface, teal for brand/action, gold for rare editorial emphasis, and coral for destructive/error states.

### Core Palette

| Role | Hex | Usage |
|---|---:|---|
| **Void** | `#080F10` | Deepest canvas, reader background, immersive base. |
| **Stage** | `#0D1516` | Main screen background for feeds, auth, settings, docs. |
| **Glass Surface** | `#111416` | Floating nav, floating controls, translucent surfaces. |
| **Card** | `#1A2122` | Main cards, form fields, info surfaces. |
| **Card High** | `#242B2C` | Elevated cards, selected tonal states, avatar/icon containers. |
| **Outline Variant** | `#3E4947` | Only for accessibility fallback at low opacity. Not for dividers. |
| **Primary Teal** | `#80D5CB` | Primary brand, active nav, primary selection, key accent text. |
| **Primary Deep** | `#2FAFA3` | Pressed/active depth, success/progress accents. Do not use as button fill. |
| **Ember Gold** | `#F4C95D` | Rare editorial highlight: ratings, curated badges, premium moments. |
| **Text Primary** | `#E2E4E6` | Main readable text. |
| **Text Muted** | `#888D93` | Metadata, descriptions, helper copy. |
| **Danger Coral** | `#FF5A6A` | Destructive actions, errors, critical feedback. |

### Semantic Color Rules

| Semantic role | Preferred color | Rule |
|---|---:|---|
| Primary action | `#80D5CB` | Use for the main path only. Buttons use Primary, not Primary Deep. |
| Success/progress | `#2FAFA3` | Reading progress, completed chapters, saved states. |
| Warning/editorial attention | `#F4C95D` | Rare. Use for ratings/highlights, not generic UI chrome. |
| Danger/error | `#FF5A6A` | Errors, destructive actions, retry danger states. |
| Info/external | Avoid by default | If blue is required, document it as a separate semantic token before use. |

### Brand Gradient

Use the brand gradient as premium capital, not decoration:

```text
linear-gradient(135deg, #80D5CB 0%, #5DA9E9 100%)
```

Allowed uses:

- Logo / wordmark treatment.
- Rare brand moments that have been explicitly approved in the design file.

Forbidden uses:

- Avatar rings.
- Primary buttons and auth buttons.
- Secondary CTAs.
- Decorative cards or badges.

---

## 3. Surface Logic & No-Line Rule

### The No-Line Rule

Do **not** use 1px dividers, borders, or separator lines for layout structure.

Use these instead:

- **Negative space** for separation.
- **Surface shifts** for grouping.
- **Typography hierarchy** for scanning.
- **Soft shadow/blur** only for floating UI.

Exception: a border may be used only as an accessibility fallback, using `#3E4947` at low opacity. Never use full-opacity borders as a default visual device.

### Surface Hierarchy

| Level | Token | Hex | Usage |
|---|---|---:|---|
| Level 0 | Void | `#080F10` | Immersive base, reader, darkest shell. |
| Level 1 | Stage | `#0D1516` | Main screen background. |
| Level 2 | Glass | `#111416` | Floating translucent surfaces. |
| Level 3 | Card | `#1A2122` | Cards, inputs, info groups. |
| Level 4 | Card High | `#242B2C` | Selected/elevated state. |

---

## 4. Typography

InkScroller uses **Plus Jakarta Sans** as the single app font.

| Role | Size / Weight | Usage |
|---|---|---|
| Display/Auth | `38–44 / 700` | Login/register hero wordmark or major entry moments. |
| Screen Title | `28–32 / 700` | Major screen headings. |
| Section Title | `18–22 / 700` | Editorial section titles and card groups. |
| Body | `14–16 / 400–500` | Descriptions, regular content. |
| Meta | `11–13 / 500` | Timestamps, counts, status labels. |

Text colors:

- Primary: `#E2E4E6`
- Secondary/muted: `#888D93`
- Tertiary: `#4A4F55` when present in Flutter tokens

Rule: if a screen feels visually weak, first check type scale and spacing before adding colors or borders.

---

## 5. Spacing, Radius & Layout Rhythm

Use spacing to create premium feel. The app should breathe.

### Spacing Scale

```text
4 / 8 / 12 / 16 / 24 / 32 / 40 / 48
```

| Pattern | Recommended spacing |
|---|---:|
| Micro gaps | `4–8` |
| Row internal gaps | `12–16` |
| Card padding | `16–20` |
| Section gaps | `24–32` |
| Editorial/hero gaps | `40–48` |

### Radius Scale

| Pattern | Radius |
|---|---:|
| Inputs / buttons | `12` |
| Manga covers / cards | `16` |
| Hero cards / large panels | `20` |
| Floating bottom nav | `28` |

---

## 6. Elevation, Glass & Motion Feel

Elevation is tonal and atmospheric, not heavy.

### Glass Surfaces

Use real blur, not just opacity.

| Component | Treatment |
|---|---|
| Floating Bottom Nav | `#111416` at 50–75%, `BackdropFilter blur(32)`, soft shadow. |
| Reader controls | `#111416` translucent + `blur(20–32)`. |
| Floating feedback | Same glass family, never hard bordered. |

### Shadows

- Floating UI: `0 12px 40px rgba(0, 0, 0, 0.4)` style shadow.
- Manga covers: color-sampled glow at low opacity when possible.
- Avoid hard drop shadows.

---

## 7. Component Contracts

### Floating Bottom Nav

- Glass surface with blur.
- Active item uses `Primary Teal`.
- No border.
- Must respect platform bottom inset.

### Tonal Tab Bar

- Active state uses color/weight/surface shift.
- Do not use underline as a divider.
- If an indicator exists, it must read as selection affordance, not section separation.

### Manga Cover Card

- 2:3 ratio.
- `16px` radius.
- Optional color-sampled glow.
- Metadata overlay should use tonal layering, not hard edges.

### Chapter Tile

- More vertical air than a standard list row.
- Separate rows with spacing, not dividers.
- Read/unread state must use icon + tonal/text difference.

### SettingsSectionCard / InfoListCard

- No internal dividers.
- Use row spacing and text hierarchy.
- Values should be more prominent than labels.

### AuthField

- Base surface: Card.
- Focus: tonal shift, not border emphasis.
- Error: coral text/icon and subtle surface response.
- States required: default, focus, error, disabled.

### Buttons

- **PrimaryButton:** `Primary Teal #80D5CB` fill, `Void #080F10` label. Use for the main action only.
- **SecondaryButton:** Card High / tonal surface.
- **DestructiveButton:** coral text/icon, dark tonal container.
- **ProviderButton:** compact circular provider icon inside a tonal container. Google auth uses this pattern, not a wide provider button.

### Profile Preference Card

- Used by logged-in and guest Profile states.
- Rows are spacing-led, no dividers.
- Logged-in copy implies synced preferences.
- Guest copy must label preferences as local/device-only in the design until implementation explicitly supports sync.

### Runtime / Fallback State Card

- Preserve context first. Partial content is better than blank screens.
- Offline with cache: show cached content with a quiet offline/stale cue.
- Offline without cache: show one clear reconnect/retry CTA.
- External chapters: leave the internal reader and clearly open the original source.

### Empty / Error State

- Use a centered state card or clear vertical stack.
- Include icon/illustration, humane copy, and one clear CTA.
- Do not look like a debug placeholder.

---

## 8. Screen-Specific Direction

| Screen | Senior UI direction |
|---|---|
| Home | Fix genre tab layout, increase section rhythm, strengthen latest-card layering. |
| Explore | Make it editorial/curated, not a rigid generic grid. Use lead tile or staggered rhythm. |
| Library | Communicate ownership and reading progress more strongly. |
| Profile | Logged-in Profile is the visual reference. Guest Profile must keep the same avatar-section rhythm, expose local preferences in the design, and keep Settings/About accessible without adding Settings to bottom nav. |
| Manga Detail | Prioritize work identity → official availability → InkScroller reading → chapters → community. Keep official source support visible before reading, move per-title language/reader-mode controls into a settings sheet, and show readable vs external chapter states clearly. |
| Reader | Use glass controls and a stronger reader header scale. |
| Auth | Remove hard input borders, use solid Primary CTAs, Google as compact circular provider icon, and keep guest escape clear. |
| Settings | Use an “App control center” model: environment card, cache TTL chips, and a separated danger action. No dividers. |
| About | Act as the legal/compliance hub: identity, quick disclaimer, MangaDex/MAL/Jikan notices, copyright notice, Railway and Firebase credits. |
| Route Error | Make it a premium state, not a default fallback. |

---

## 9. Do / Don’t

### Do

- Use teal as the main brand/action color.
- Let neutrals create most of the UI depth.
- Use Ember Gold rarely for editorial moments.
- Separate content with spacing and surface shifts.
- Keep Plus Jakarta Sans as the single app font.
- Design reader/auth/error states as first-class experiences.

### Don’t

- Don’t make everything teal.
- Don’t add more colors just because a screen feels flat.
- Don’t use 1px dividers for structure.
- Don’t overuse the brand gradient.
- Don’t use pure black `#000000`.
- Don’t solve hierarchy problems with random borders or shadows.

---

## 10. Manga Detail Product Contract

Manga Detail is not just a metadata page. It is the handoff from discovery to reading, with compliance and source clarity built into the flow without turning the screen into legal copy.

### Required order

1. **Work identity** — cover, title, status/tags, score/rank when available, synopsis.
2. **Official availability** — pills for official platforms and a short note that availability can vary by region/language.
3. **Read in InkScroller** — compact primary read action plus quieter secondary actions.
4. **Chapters** — current language and reader mode shown inline; tune/settings opens per-title controls.
5. **Community** — compact teaser only; expanded comments live in a secondary state.

### Source and compliance guidance

- Do not repeat MangaDex/Jikan attribution beside every metadata field.
- Keep the full non-affiliation disclaimer in About/Settings.
- Keep contextual source cues where they affect user choice: official availability, scanlation group on chapter rows, and external-link chapter rows.
- External chapters must not look like internal reader chapters. Use a clear external affordance and copy such as "Available on MangaPlus".

### Per-title settings

Use the Manga Detail tune/settings action for controls that affect this title only:

- Reading mode: Default / Vertical / Paged.
- Chapter language: active language and alternatives.
- If the active language has no chapters, show alternatives before implying the manga is empty.

---

## 11. Phase 6 Editable Design Inventory

The active Pencil source of truth is `design/designApp`. The deprecated `design/pencil/inkscroller.pen` must not be used.

| Area | Pencil coverage | Notes |
|---|---|---|
| Main tabs | Home, Explore, Library, Profile logged-in, Profile guest | Guest Profile is a public account/app hub. |
| Reading flow | Manga Detail, Reader, Reader Components, Manga settings, language empty states, community comments | Reader main screen is stable; fallback coverage lives in runtime boards. |
| Auth/settings/docs | Login, Register, auth provider strategy, auth runtime states, Settings, About, Route Error, Design System Summary | Android/Firebase first; Google + email/password + guest. Apple is deferred. |
| Runtime states | Loading, Empty, Error, Offline/Fallback | Offline/Fallback covers cached reader, no cache, external chapters, stale catalogue, partial detail/chapter failure. |
| Component library | Phase 6 component grid | Reflects current patterns: Primary CTAs, preference cards, settings/cache cards, reader/runtime states. |

---

## 12. Final Phase 6 Decisions

| Topic | Decision |
|---|---|
| Button color | Button fills use `Primary #80D5CB`, not `Primary Deep #2FAFA3`. |
| Profile guest | Keep Profile public as an account/app hub. Do not add Settings to the bottom nav. |
| Guest preferences | Represent reader mode, app language, and manga language as local/device preferences in design. Implementation is a separate task. |
| Auth providers | Android/Firebase scope: Google, email/password, guest. Google is a circular provider icon, not a wide button. |
| About infrastructure credit | Backend infrastructure credit is Railway. |
| Legal burden | About carries the full disclaimer. Manga Detail uses contextual source cues only. |
| Offline/fallback | Use dedicated fallback states instead of treating every network issue as a generic error. |

---

## 13. Implementation Priority

1. Add/align Pencil variables and Flutter tokens with this document.
2. Differentiate Explore and Library visually.
3. Remove dividers from Settings/About/Auth patterns.
4. Improve Manga Detail + Reader layering and glass controls.
5. Implement Profile guest hub and local preference affordances.
6. Polish Auth and runtime/offline fallback states.
