# Central theme tokens

## Context

Hardcoded colors and text styles drift between light and dark mode, and a new project should recolor the starter in one place.

## Decision

`AppColors.brand` seeds both Material 3 schemes. Typography, spacing, and radius are token files. Success, warning, border, and disabled colors are the `AppStatusColors` theme extension. `ThemeModeController` persists light, dark, and system. No third-party theme package is used. Icons go through `AppIcons`, which points at Remix glyphs and at Flutter's built-in icons.

## Alternatives considered

- A dynamic theme engine with runtime color schemes. The starter does not need it.
- `cupertino_icons` plus Material icons. Remix covers the product glyphs, and Flutter's `Icons` remain available for the few Material glyphs.
- Separate light and dark widgets. The theme already switches.

## Consequences

A new brand color is a one-line change. A new semantic color is a field on the extension, with a light and a dark value. Screens do not embed `Color(0xFF...)`.
