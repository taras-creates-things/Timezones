# Contributing to Timezones

Thanks for helping improve Timezones. Focused bug reports, design feedback, and small pull requests are especially welcome while the project is in its early preview stage.

## Before you begin

- Search existing issues before opening a new one.
- Open an issue before starting a large feature or visual redesign so the direction can be agreed first.
- Keep pull requests limited to one clear change.
- Do not include credentials, personal data, generated build output, or unrelated formatting changes.

## Local setup

1. Install Xcode 26 or newer on macOS 14 or newer.
2. Clone the repository and open `Timezones.xcodeproj`.
3. Select the **Timezones** scheme and **My Mac** destination.
4. Build and run the project.

The app targets macOS and does not currently support development from Linux or Windows.

## Testing

Before submitting a pull request, run:

```bash
xcodebuild test \
  -project Timezones.xcodeproj \
  -scheme Timezones \
  -destination 'platform=macOS'
```

Please add or update tests when changing timezone calculations, work-status rules, persistence, or model behavior.

## Pull requests

A good pull request:

- Explains the user-facing problem and the chosen solution
- Includes screenshots or a short recording for visual changes
- Preserves the existing typography, spacing, and interaction language
- Builds without warnings introduced by the change
- Passes the complete test suite

By contributing, you agree that your contribution may be distributed under the repository's current or future project license.
