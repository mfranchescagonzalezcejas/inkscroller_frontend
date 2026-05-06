# Design System: The Cinematic Canvas

## 1. Overview & Creative North Star
**Creative North Star: "The Silent Frame"**

This design system is built on the philosophy of "Editorial Immersion." In the world of manga and webtoons, the artwork is the protagonist; the UI is the theater. We move away from the "app-like" density of standard readers and toward a high-end, cinematic gallery experience. 

By utilizing **Intentional Asymmetry**, we break the rigid verticality of mobile scrolling. Large-scale typography and overlapping elements create a sense of depth and curated "white space" (even in a dark void). The goal is to make the user feel they are not just using a tool, but entering a premium digital archive.

---

## 2. Colors & Surface Logic

The palette is anchored in a deep, atmospheric teal and "Void" neutrals. We reject the "flat" dark mode in favor of tonal layering.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning or containment. 
Boundaries must be defined solely through:
- **Surface Shifts:** Placing a `surface-container-low` (#161D1E) card against a `surface` (#0D1516) background.
- **Negative Space:** Using the Spacing Scale (specifically `spacing-8` or `spacing-10`) to create structural "gutters."

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Use the `surface-container` tiers to create "nested" depth:
1.  **Level 0 (The Void):** `surface-container-lowest` (#080F10) – Used for the base canvas of the reader.
2.  **Level 1 (The Stage):** `surface` (#0D1516) – The primary background for lists and feeds.
3.  **Level 2 (The Card):** `surface-container` (#1A2122) – For individual content modules.
4.  **Level 3 (The Floating):** `surface-bright` (#333A3C) – For elements requiring the highest visual prominence.

### The "Glass & Gradient" Rule
To elevate the experience, use **Glassmorphism** for floating elements. 
- **Floating Nav/Modals:** Use `surface` (#111416) at **75% opacity** with a **20px backdrop-blur**.
- **Signature Gradient:** The `linear-gradient(135deg, #0F766E, #1E40AF)` is a high-luxury asset. Reserve it exclusively for the brand logo and the "Start Reading" primary action to signal a transition from "browsing" to "experience."

---

## 3. Typography: The Editorial Scale

We use **Plus Jakarta Sans** to balance modern tech with editorial elegance. 

- **Display Scale:** Use `display-lg` and `display-md` with **Bold (700)** weights for title screens. This creates an authoritative, "magazine cover" feel.
- **Hierarchy of Focus:** 
    - **Primary Text:** `on-surface` (#E2E4E6) - Used for chapter titles and headers.
    - **Secondary Text:** `on-surface-variant` (#888D93) - Used for author names and metadata.
    - **Muted Text:** `outline` (#4A4F55) - Used for timestamps and non-interactive tertiary info.
- **Asymmetric Spacing:** Titles should often utilize `spacing-5` (1.7rem) leading to create breathing room, avoiding the "cramped" feel of traditional apps.

---

## 4. Elevation & Depth

We convey hierarchy through **Tonal Layering** rather than structural lines or heavy shadows.

- **The Layering Principle:** Stack `surface-container-low` cards on a `surface` background to create a soft, natural lift. 
- **Ambient Shadows:** For floating elements like the Bottom Nav, use an extra-diffused shadow: `box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4)`. The shadow must feel like an ambient occlusion, not a hard drop-shadow.
- **The "Ghost Border" Fallback:** If a border is required for accessibility (e.g., in a search input), use `outline-variant` (#3E4947) at **20% opacity**. Never use 100% opaque borders.
- **Glassmorphism:** Apply to the Floating Bottom Nav and Top Bar. This allows the vibrant manga cover art to bleed through the UI as the user scrolls, maintaining a connection to the content.

---

## 5. Signature Components

### Floating Bottom Nav
- **Specs:** 56px height, 20px radius (`xl`), 16px side margins.
- **Visuals:** 75% opacity `surface-container` + 20px blur. No border. Active icons use `primary` (#80D5CB) with a subtle glow.

### The "Hero" Card
- **Logic:** Manga covers should use `radius-lg` (16px).
- **Shadow:** Use a color-sampled "Glow Shadow" (40% opacity of the cover's dominant color) instead of black to make the covers pop against the Void.

### Buttons
- **Primary (Start Reading):** Brand Gradient background, `on-primary-fixed` text, `radius-md` (12px).
- **Secondary (Action/Filter):** `surface-container-high` background, `on-surface` text. No border.
- **Tertiary (Minimal):** No background. `primary` text.

### Inputs
- **Surface:** `surface-container-highest` (#181B1E).
- **Interaction:** On focus, the background shifts to `surface-bright`. No border change; only a subtle tonal shift.

### Cards & Lists
- **Rule:** Forbid divider lines. Use `spacing-6` (2rem) between list items to let the content breathe. Use `surface-container-low` for card backgrounds to distinguish them from the base canvas.

---

## 6. Do’s and Don’ts

### Do:
- **Do** allow manga covers to overlap background elements or text slightly to create a 3D layered effect.
- **Do** use the `secondary` (#4DDC6) and `accent` (#5EEAD4) colors sparingly for "New Chapter" badges to ensure they feel like jewels in the dark.
- **Do** prioritize large vertical spacing (`spacing-10` or `spacing-12`) between sections (e.g., "Trending" vs "Library").

### Don't:
- **Don't** use pure black (#000000). Always use the "Void" neutrals to maintain a premium, ink-like depth.
- **Don't** use 1px dividers or borders. If elements feel too close, increase the spacing scale rather than adding a line.
- **Don't** use the Brand Gradient for anything other than the Logo and the "Start Reading" CTA. Overuse diminishes its premium impact.