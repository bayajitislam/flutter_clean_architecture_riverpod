# Flutter UI

Screens compose shared widgets. They do not invent a second button, text field, or dialog style.

- Use `AppButton`, `AppTextField`, `AppLoading`, `AppErrorView`, and `showAppConfirmDialog`.
- Read colors and text styles from the theme (`Theme.of(context)`, `context.colors`, `context.textTheme`).
- Read success, warning, border, and disabled colors from `context.statusColors`.
- Use `AppSpacing` and `AppRadius` for padding and corners.
- Use `AppIcons` for icons. Remix glyphs are the default fields. Flutter's built-in icons are the Material fields on the same class. Add a new glyph there.
- Keep `ThemeMode` in `themeModeControllerProvider`. Call `setThemeMode`. Do not store the mode in a widget field.
- Give icon-only controls a tooltip.
- Validate a form before calling a use case, and show the returned `Failure.message` when the call fails.

## Screen sizes

Width comes from `LayoutBuilder`, not from the operating system. `AppBreakpoints` defaults to 600 for tablet and 1024 for desktop. Pass a different `AppBreakpoints` when a project needs other widths. Resizing the window changes the layout on the next frame.

`ResponsiveBody` is the shared responsive wrapper. It keeps one design readable on every width. Login and home use it.

`AdaptiveLayout` is for a screen whose arrangement changes, or whose mobile, tablet, and desktop designs are different. Omit `tablet` or `desktop` and the next smaller layout is used. A new feature can ship with `mobile` only.

## Which strategy to use

1. Shared responsive UI. One screen is enough when the same design works everywhere. Use `ResponsiveBody`.
2. Adaptive UI. One screen changes navigation, spacing, columns, or arrangement. Keep the widgets in that screen and branch on `screenSizeOf`.
3. Separate layouts. Add `screens/mobile`, `screens/tablet`, and `screens/desktop` only when the experience is substantially different. The showcase feature is the reference. Its three screens read one controller.

Do not create three screens for a simple page. Do not copy a repository, provider, or use case into a second layout.

## Adding tablet or desktop later

1. Leave the provider, use case, and repository where they are.
2. Move the current screen to `presentation/screens/mobile/` if the new design should not share that widget tree.
3. Add `presentation/screens/tablet/` or `presentation/screens/desktop/`.
4. Return them from `AdaptiveLayout` next to the mobile screen.
5. Put widgets used by more than one layout in `presentation/widgets/shared/`.
6. Use `AdaptiveNavigation` only when the screen needs bottom navigation, a rail, or a sidebar. Mobile uses the bottom bar, a tablet uses a rail, and desktop uses a sidebar. A tablet at 840 logical pixels or wider extends the rail for landscape.

## Theme

`AppTheme.light` and `AppTheme.dark` are Material 3 themes. `AppColors.brand` is the seed for both. `MaterialApp.router` receives those themes and the mode from `themeModeControllerProvider`.

`ThemeMode.system` follows the operating system. The controller restores the saved mode at startup and writes it only when `setThemeMode` receives a different mode. `toggle` cycles light, dark, then system.

Change the look in one place:

- Brand, success, and warning colors: `lib/core/theme/app_colors.dart`.
- Type family: `AppTypography.fontFamily`. Display, headline, title, body, and label come from the Material text theme. Buttons use `labelLarge`.
- Spacing and radius: `AppSpacing` and `AppRadius`.
- A color Material does not have: add a field to `AppStatusColors`, set it in `light` and `dark`, and read it with `context.statusColors`.

Widgets use the same theme on mobile, tablet, and desktop. Light and dark differences belong in the theme, not in a second widget.

## Contributing a widget or screen

Shared widgets live in `lib/shared` when more than one feature uses them, and in `lib/core/widgets` when they are application controls. A widget used by one feature stays in that feature. Screens compose those widgets and call use cases. Add the screen with `dart run tool/awesome.dart feature create <name>`, then register its route.

## Do not

- Hardcode `Color(0xFF...)` or a `TextStyle` inside a feature screen. Add a shared color to `AppColors` or `AppStatusColors`.
- Call `setState` to store a session, a token, or a network response.
- Build a new `Scaffold` design for a single button.
- Detect the platform instead of measuring the available width.
