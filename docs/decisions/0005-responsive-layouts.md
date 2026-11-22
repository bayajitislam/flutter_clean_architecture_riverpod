# One layout unless the experience changes

## Context

Shipping mobile, tablet, and desktop widgets for every screen triples the UI without helping a simple form.

## Decision

Width comes from `LayoutBuilder`. Tablet starts at 600 logical pixels and desktop at 1024. Those values are `AppBreakpoints`. Login and home use one `ResponsiveBody`. A screen with a different arrangement uses `AdaptiveLayout`. Separate mobile, tablet, and desktop files exist only in the showcase, which is the reference, and they share one provider.

The feature generator writes one screen.

## Alternatives considered

- Always generate three screens. Most features would be copies.
- Branch on the operating system. A wide phone and a narrow desktop window would be wrong.

## Consequences

Contributors add a second layout when they can show that the first one fails. Navigation chrome is opt-in through `AdaptiveNavigation`.
