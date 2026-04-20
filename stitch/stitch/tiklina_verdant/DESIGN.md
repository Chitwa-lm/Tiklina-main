# Design System Strategy: The Living Ecosystem

## 1. Overview & Creative North Star
This design system is built on the Creative North Star of **"The Digital Steward."** In a sector often defined by grime and industrial utility, we pivot toward a high-end editorial experience that feels like a premium lifestyle brand. We move away from the "utility app" aesthetic into a space of organic sophistication.

The design breaks the standard Material 3 template by utilizing **Intentional Asymmetry** and **Layered Depth**. We treat the screen not as a flat grid, but as a digital landscape where information "grows" and "breathes." By utilizing a high-contrast typography scale and wide-open spatial breathing room, we ensure the interface is as legible for low-tech users as it is aesthetically pleasing for the modern eco-conscious citizen.

---

## 2. Color & Surface Philosophy
The palette is grounded in the vitality of `primary` (#176a21) and the urgency of `secondary` (#8b4b00). We avoid the sterile "hospital white" by leaning into a sophisticated `surface` (#f5f6f7).

### The "No-Line" Rule
To achieve a premium, editorial feel, **1px solid borders are strictly prohibited** for sectioning. Boundaries must be defined solely through:
- **Tonal Transitions:** Placing a `surface-container-low` section against a `surface` background.
- **Negative Space:** Using the Spacing Scale (6 or 8 tokens) to separate content groups.

### Surface Hierarchy & Nesting
Think of the UI as a series of physical layers. Use the surface-container tiers to create "nested" depth:
1. **The Base:** `surface` (#f5f6f7) for the main canvas.
2. **The Section:** `surface-container-low` (#eff1f2) for large content areas.
3. **The Interactive Element:** `surface-container-lowest` (#ffffff) for primary cards or input fields to create a natural, "raised" appearance against the slightly darker background.

### The Glass & Gradient Rule
For floating elements (modals, navigation bars), use **Glassmorphism**. Apply `surface-container-lowest` at 80% opacity with a `24px` backdrop blur. For primary CTAs, apply a subtle linear gradient from `primary` (#176a21) to `primary_dim` (#025d16) at a 135-degree angle to provide "soul" and professional polish.

---

## 3. Typography
We employ a dual-typeface strategy to balance character with extreme legibility.

*   **Display & Headlines (Manrope):** Chosen for its geometric clarity and modern "roundness." Large `display-lg` (3.5rem) and `headline-md` (1.75rem) scales create a confident, editorial hierarchy that guides the eye immediately.
*   **Body & Labels (Inter):** The workhorse for utility. High x-height and neutral character make `body-lg` (1rem) highly legible for all user demographics, particularly when set in `on_surface` (#2c2f30) for maximum contrast.

---

## 4. Elevation & Depth
In this system, elevation is a feeling, not a shadow. 

*   **The Layering Principle:** Depth is achieved by stacking. Place a `surface-container-lowest` card on a `surface-container-low` section. This "soft lift" mimics fine stationery and feels more premium than heavy drop shadows.
*   **Ambient Shadows:** If an element must float (e.g., a "Schedule Pickup" FAB), use an extra-diffused shadow: `offset: 0px 8px`, `blur: 24px`, `color: rgba(44, 47, 48, 0.06)`. This mimics natural ambient light rather than digital "glow."
*   **The Ghost Border Fallback:** If a border is required for accessibility in forms, use the `outline_variant` token at **15% opacity**. Never use 100% opaque lines.

---

## 5. Components

### Buttons
*   **Primary:** Full-width (utilizing the `16` or `20` spacing tokens for horizontal margins). Radius: `xl` (1.5rem/24px). Background: Gradient of `primary` to `primary_dim`.
*   **Secondary:** Ghost-style. No fill, `Ghost Border` (15% `outline_variant`), text in `primary`.
*   **States:** On press, scale down slightly (98%) to provide haptic-like visual feedback.

### Cards & Lists
*   **Card Container:** Radius `xl` (1.5rem). Use `surface-container-lowest` background. 
*   **Anti-Divider Policy:** Never use horizontal rules (`<hr>`). Separate list items using `spacing-4` (1.4rem) or by alternating background tones slightly between `surface-container-lowest` and `surface-container-low`.

### Input Fields
*   **Aesthetic:** Large, airy fields with a `surface-container-lowest` fill. 
*   **Active State:** Transition the "Ghost Border" to a 2px `primary` border to signal focus.
*   **Error State:** Use `error` (#b02500) text with a `surface-container` background tinted slightly with `error_container`.

### Context-Specific Components
*   **The "Impact Tracker" Widget:** A glassmorphic card using `tertiary_container` for positive environmental stats (CO2 saved, etc.), creating a visual "gem" within the earthy green ecosystem.
*   **Waste Category Chips:** Large selection chips (radius `full`) using `primary_container` when active, ensuring they are easy to tap for users on the go.

---

## 6. Do's and Don'ts

### Do
*   **DO** use whitespace as a functional tool. If a screen feels cluttered, increase spacing by two scale steps.
*   **DO** use "Primary Fixed" colors for elements that must remain vibrant across light/dark transitions.
*   **DO** align text-heavy sections with generous leading (line-height) to assist low-tech users.

### Don't
*   **DON'T** use black (#000000) for text. Always use `on_surface` (#2c2f30) to maintain a soft, premium feel.
*   **DON'T** use the `secondary` orange for decorative elements. Reserve it strictly for "Alerts," "Warnings," or "Immediate Actions."
*   **DON'T** use 90-degree corners. Everything in this ecosystem is organic; stick to the `xl` (1.5rem) or `lg` (1rem) roundedness scale.