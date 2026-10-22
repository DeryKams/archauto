# Archauto — Desktop Design Guidelines

## 1. Project Overview

This project provides a customized desktop environment based on Arch Linux and the Niri Wayland compositor.

These instructions define the **permanent design language and engineering standards** for desktop configuration files.

They are not a one-time redesign task.

Whenever creating, editing, or extending desktop UI components, follow these guidelines while preserving existing functionality.

### Architecture

- **Operating System:** Arch Linux
- **Compositor:** Niri
- **Panel:** Waybar
- **Launcher:** Walker + Elephant
- **Notifications:** SwayNC
- **Terminal:** Kitty
- **Display Manager:** GDM
- **Application Toolkits:** GTK / Qt
- **Dotfiles Management:** GNU Stow

---

## 2. Design Philosophy

The desktop follows an **Apple-inspired Liquid Glass design language**, emphasizing transparency, visible glass boundaries, elegant geometry, subtle lighting, and fluid interactions.

### Primary Design Principle

**Prefer transparent or translucent elements with clearly defined borders over opaque, solid-colored surfaces.**

The appearance should resemble layers of carefully shaped glass floating above the desktop, rather than a collection of colored rectangles.

A successful implementation should emphasize:

- Transparency instead of solid background fills.
- Clearly visible, elegant outlines.
- Frosted glass instead of flat colored surfaces.
- Subtle reflections and highlights.
- Depth through layered transparency and shadows.
- Consistent rounded geometry.
- Minimal visual noise.
- Smooth, restrained animations.
- Excellent readability and usability.

**Glass should be defined primarily by its boundaries, transparency, lighting, and depth — not by its fill color.**

### Design Intent

The desktop should feel:

- Clean and lightweight.
- Refined and minimal.
- Spacious but not oversized.
- Visually cohesive.
- Calm and responsive.
- Modern without excessive decoration.

Do not introduce bright, saturated, or opaque backgrounds merely to distinguish interface elements.

Use outlines, transparency, spacing, typography, and subtle highlights to create visual hierarchy.

---

## 3. Visual Priority Rules

When designing a UI element, apply the following preferences in order:

1. Transparent background with a clearly visible border.
2. Subtle translucent background with a clearly visible border.
3. Frosted translucent surface with compositor-supported background blur.
4. Lightly tinted translucent surface for contrast or hierarchy.
5. Opaque solid-colored surface only when required for readability, accessibility, or functionality.

### Important Rules

- Do not use solid colors as the default background of buttons, modules, cards, or menus.
- Do not replace translucent glass elements with opaque colored rectangles during routine edits.
- Prefer borders and highlights to distinguish adjacent elements.
- Use colored accents primarily for focus, selection, status, and important interactions.
- Preserve the glass appearance across normal, hover, active, selected, and disabled states.
- Avoid unnecessarily dark or heavily tinted backgrounds.
- Avoid turning the interface into a collection of separate solid-colored blocks.
- Never sacrifice readability or accessibility solely to increase transparency.

A component should remain visually recognizable even when its background is nearly transparent.

---

## 4. Glass Surfaces

### Transparency

Transparency is a core part of the desktop design.

- Prefer transparent or semi-transparent backgrounds.
- Use RGBA colors where supported.
- Keep glass surfaces visually lightweight.
- Allow the underlying wallpaper to contribute to the appearance.
- Use subtle tinting only when necessary.
- Maintain sufficient contrast against both light and dark backgrounds.
- Avoid stacking excessive translucent layers that create muddy colors.

### Background Blur

Prefer background blur when supported by Niri and the relevant surface or application.

- Verify compositor support before enabling blur.
- Use moderate blur rather than excessive diffusion.
- Do not assume CSS transparency automatically produces background blur.
- Do not use unsupported browser-only CSS properties in GTK stylesheets.
- Where blur is unavailable, preserve the transparent, outlined appearance.
- Increase surface opacity when necessary for readability.

**Never represent transparency alone as equivalent to frosted glass.**

### Surface Hierarchy

Use transparency, border intensity, and depth to distinguish interface layers.

- **Base surfaces:** Maximum practical transparency and minimal visual weight.
- **Raised surfaces:** Slightly more visible outlines and subtle shadows.
- **Floating panels:** Stronger boundaries and increased background separation.
- **Active elements:** Clearer borders and soft accent highlights.
- **Disabled elements:** Reduced opacity without introducing unnecessary fills.

Avoid using progressively more saturated solid backgrounds to create hierarchy.

---

## 5. Borders and Glass Outlines

**Visible borders are a defining feature of this design system.**

Borders should clearly separate transparent elements from their surroundings while maintaining an elegant appearance.

### Border Rules

- Prefer 1px borders for ordinary components.
- Use 2px borders sparingly for focus indicators or important active states.
- Prefer semi-transparent white, silver, or neutral borders.
- Make boundaries sufficiently visible against the wallpaper.
- Use consistent border thickness throughout the interface.
- Avoid heavy black outlines.
- Avoid bright neon borders.
- Avoid excessive multi-layered borders.

### Lighting and Highlights

- Use subtle light-colored edge highlights.
- Prefer gentle reflections along upper or exposed edges.
- Use restrained accent highlights for focused or selected elements.
- Create depth without aggressive glow.
- Avoid excessive gradients and decorative lighting.

### Border Priority

When an element needs stronger visual separation:

1. Increase border contrast.
2. Adjust spacing.
3. Add a subtle highlight or shadow.
4. Slightly increase background opacity if necessary.
5. Use an opaque background only as a last resort.

Do not immediately replace the background with a stronger solid color.

---

## 6. Geometry and Spacing

All desktop elements should follow a consistent system of rounded geometry.

### Recommended Corner Radii

- Small buttons and controls: **8–12px**
- Waybar modules and compact widgets: **10–14px**
- Cards and notification elements: **12–18px**
- Floating panels and dialogs: **16–22px**
- Large overlays and search interfaces: **18–24px**

### Layout Principles

- Maintain consistent spacing between adjacent components.
- Avoid cramped controls.
- Keep padding balanced.
- Prefer rounded rectangular shapes.
- Use pill-shaped controls when appropriate.
- Align icons and text consistently.
- Preserve the functional density of existing interfaces.

Do not increase padding or corner radii merely for decorative purposes.

---

## 7. Shadows and Depth

Shadows should establish the visual relationship between floating glass layers and their background.

### Requirements

- Prefer soft, diffuse shadows.
- Avoid sharply defined dark shadows.
- Keep shadow opacity restrained.
- Use consistent shadow direction.
- Apply stronger depth primarily to floating panels and dialogs.
- Avoid large shadows around every small interface element.

### Depth Hierarchy

- Ordinary controls: Little or no shadow.
- Raised controls: Subtle shadow.
- Cards: Soft shadow.
- Floating menus: Moderate shadow.
- Dialogs and large overlays: More pronounced depth.

Combine shadows with clear outlines rather than relying on shadows alone.

---

## 8. Color System

The existing desktop uses a dark, neutral-blue palette.

Preserve its overall character, but **prefer translucent versions of these colors over opaque fills**.

### Reference Palette

- Base: `#192638`
- Raised surface: `#25344a`
- Selected surface: `#344d70`
- Primary text: `#edf2fa`
- Secondary text: `#aebdd0`
- Accent: `#73acfa`
- Original border: `#34445a`

These values are references, not mandatory opaque backgrounds.

### Preferred Glass Tokens

The following values are starting points and should be adjusted for contrast, toolkit support, and underlying wallpaper.

- Transparent base: `rgba(25, 38, 56, 0.12)`
- Glass surface: `rgba(25, 38, 56, 0.28)`
- Elevated glass: `rgba(25, 38, 56, 0.42)`
- Glass hover: `rgba(255, 255, 255, 0.12)`
- Glass active: `rgba(255, 255, 255, 0.18)`
- Glass border: `rgba(255, 255, 255, 0.40)`
- Strong glass border: `rgba(255, 255, 255, 0.60)`
- Soft highlight: `rgba(255, 255, 255, 0.20)`
- Accent border: `rgba(115, 172, 250, 0.85)`
- Primary text: `#edf2fa`
- Secondary text: `#aebdd0`

### Color Usage Rules

- Prefer transparency over saturated backgrounds.
- Prefer light neutral outlines over dark filled surfaces.
- Use accent colors primarily for borders, focus indicators, and small details.
- Avoid large solid blue rectangles.
- Avoid unnecessary color variation between adjacent widgets.
- Preserve readable text contrast.
- Adapt opacity when wallpaper brightness affects readability.

### Dark and Light Appearance

Maintain a coherent dark glass appearance by default.

Support a light glass variant when explicitly requested or when the project already provides one.

Do not unexpectedly switch the desktop between light and dark themes.

---

## 9. Interaction States

Every interactive component must have visually consistent states.

### Normal

- Transparent or lightly translucent background.
- Clearly visible border.
- Readable foreground.
- Minimal visual weight.

### Hover

- Slightly brighter border.
- Subtle increase in background opacity.
- Optional soft highlight.
- No abrupt transition to an opaque background.

### Active or Selected

- More prominent outline.
- Restrained accent color.
- Slightly stronger translucent surface.
- Clearly distinguishable from the normal state.

### Focused

- Visible and accessible focus indicator.
- Prefer a defined accent outline.
- Avoid relying exclusively on changes in background color.

### Disabled

- Reduced contrast and opacity.
- Maintain recognizable component boundaries.
- Avoid adding unnecessary solid backgrounds.

Hover and active states should feel like **light interacting with glass**, rather than colored blocks switching between solid fills.

---

## 10. Typography

Typography should feel clean, modern, and consistent.

### Requirements

- Prefer Cantarell unless explicitly changed.
- Maintain consistent font families across components.
- Use restrained font weights.
- Establish hierarchy through size, weight, and spacing.
- Avoid unnecessary uppercase labels.
- Preserve text readability on translucent surfaces.
- Keep labels concise.

Do not compensate for poor surface contrast solely with excessively bold typography.

---

## 11. Animations and Motion

The desktop should use smooth, fluid, understated motion inspired by Apple's interface design.

### Requirements

- Prefer smooth and responsive transitions.
- Use restrained easing.
- Avoid excessive bouncing.
- Avoid distracting overshoot.
- Keep hover transitions subtle.
- Preserve responsiveness.
- Prefer native Niri animation capabilities.
- Respect accessibility preferences where available.

Animation should communicate interaction and spatial relationships, not exist merely for decoration.

---

## 12. Component-Specific Guidelines

### Niri

Niri controls window geometry, focus, movement, and compositor-supported visual effects.

- Maintain consistent window rounding.
- Use soft, balanced shadows.
- Keep gaps visually proportional.
- Prefer elegant focus outlines.
- Configure smooth animations.
- Use blur and background effects only when supported by the installed version.
- Preserve existing window rules.
- Preserve keyboard shortcuts and window-management behavior.
- Validate configuration syntax before applying changes.

### Waybar

Waybar should resemble an elegant collection of transparent glass controls.

- Prefer transparent modules with clearly defined borders.
- Avoid opaque colored backgrounds.
- Use consistent corner radii and spacing.
- Apply subtle hover highlights.
- Use accent-colored outlines for important states.
- Keep panel and widget styling visually cohesive.
- Avoid excessive visual separation between neighboring modules.
- Preserve all existing widgets, commands, menus, and interactions.

**Do not replace the glass appearance with solid-colored module backgrounds.**

### Walker

Walker should follow an Apple Spotlight-inspired visual style.

- Prefer a floating glass search interface.
- Use a translucent search container.
- Maintain a clearly defined outer border.
- Use restrained interior separators.
- Prefer outlined or softly highlighted search results.
- Keep selected results visibly distinct without heavy opaque fills.
- Maintain consistent rounded geometry.
- Preserve Elephant integration and provider functionality.

### SwayNC

SwayNC should resemble a glass-inspired notification and control center.

- Use translucent notification cards.
- Give each card a clearly visible outline.
- Maintain consistent spacing and rounded corners.
- Prefer subtle hover highlights.
- Avoid opaque backgrounds for ordinary notifications.
- Keep action buttons visually consistent with other controls.
- Maintain readable notification content.
- Preserve notification behavior and existing controls.

### Kitty

Kitty should visually integrate with the desktop.

- Prefer subtle terminal background transparency.
- Preserve text and cursor contrast.
- Maintain terminal performance and readability.
- Use compositor-supported blur only where compatible.
- Preserve existing shell configuration and terminal functionality.

### GTK and Qt

Application styling should follow the same design principles where toolkit capabilities permit.

- Prefer transparent or lightly translucent elements.
- Use consistent rounded geometry.
- Maintain visible borders and focus indicators.
- Preserve readable text and accessible controls.
- Do not assume browser CSS capabilities exist in GTK.
- Do not use unsupported styling properties.
- Avoid modifying unrelated applications.
- Preserve native application functionality.

### GDM

Maintain a consistent visual identity where supported.

- Prefer clean and minimal styling.
- Preserve login functionality and accessibility.
- Avoid fragile system-level modifications.
- Do not replace login components without explicit approval.

---

## 13. Visual Consistency Rules

New components should visually belong to the existing desktop.

Before creating or modifying a widget:

1. Inspect nearby components.
2. Identify their spacing, radii, typography, and border styles.
3. Reuse compatible glass styling.
4. Prefer transparent surfaces.
5. Preserve clear visual boundaries.
6. Keep interaction states consistent.
7. Avoid introducing unrelated colors or decorative effects.

### Avoid

- Opaque colored cards.
- Heavy solid backgrounds.
- Excessive saturation.
- Thick dark borders.
- Aggressive glowing effects.
- Inconsistent corner radii.
- Excessive shadows.
- Unnecessary gradients.
- Decorative animations that interfere with usability.
- Different visual styles for components serving similar purposes.

### Prefer

- Transparent backgrounds.
- Clear glass outlines.
- Soft reflections.
- Subtle highlights.
- Restrained shadows.
- Consistent geometry.
- Neutral colors.
- Balanced spacing.
- Fluid interactions.
- Strong visual cohesion.

---

## 14. Engineering Constraints

Visual changes must not compromise functionality.

### General Rules

- Preserve existing functionality.
- Preserve keyboard shortcuts unless explicitly requested.
- Preserve existing commands and application integrations.
- Do not modify user-defined Zsh functions, aliases, or personal settings.
- Do not introduce duplicate packages or services.
- Do not replace existing components without explicit approval.
- Preserve the GNU Stow directory structure.
- Prefer existing dependencies and native capabilities.
- Avoid unnecessary background processes.
- Minimize performance overhead.
- Keep changes limited to relevant files.
- Preserve user data and configuration behavior.

### Compatibility

- Verify support for visual effects in the installed component version.
- Distinguish browser CSS from GTK CSS.
- Do not assume compositor blur applies to every Wayland surface.
- Do not claim an effect is functional without verification.
- Provide graceful visual fallbacks when effects are unsupported.

---

## 15. Implementation Workflow

When modifying desktop-related files:

1. Inspect the current configuration.
2. Identify relevant functional dependencies.
3. Review existing design conventions.
4. Apply the transparent, border-first glass design.
5. Preserve existing functionality and personal customizations.
6. Verify compatibility with installed software versions.
7. Validate syntax using available tools.
8. Review changes for unintended modifications.
9. Verify readability and interaction states where possible.
10. Report meaningful changes, limitations, and unsupported effects.

Avoid rewriting unrelated configuration sections.

Do not perform broad redesigns unless explicitly requested.

---

## 16. Design Decision Hierarchy

When multiple implementations are possible, use the following priority:

1. Functional correctness and safety.
2. Transparent surfaces with clearly defined borders.
3. Consistency with the Apple-inspired Liquid Glass design language.
4. Readability and accessibility.
5. Native compositor and toolkit compatibility.
6. Performance and responsiveness.
7. Minimal dependencies.
8. Maintainability.

When choosing between a solid-colored component and a transparent outlined component that are equally functional and readable, **always prefer the transparent outlined component**.

---

## 17. Permanent Design Directive

The defining characteristic of this desktop is:

**Transparent glass surfaces, crisp visible outlines, soft depth, and minimal reliance on opaque color fills.**

This principle applies to all future desktop UI work covered by these instructions.

Do not treat these guidelines as a request to immediately redesign the entire environment.

Instead, continuously apply them when creating or modifying relevant desktop components.

Preserve the user's existing functionality, preferences, and system behavior.