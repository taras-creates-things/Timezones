<div align="center">

# Timezones

### A precise, tactile world clock for the macOS menu bar.

[![CI](https://github.com/taras-creates-things/Timezones/actions/workflows/ci.yml/badge.svg)](https://github.com/taras-creates-things/Timezones/actions/workflows/ci.yml)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)

</div>

Timezones keeps your clients, teammates, and cities aligned around the same instant. Drag one tactile timeline and every tracked timezone moves with it—complete with daylight-saving changes, fractional offsets, working-hour context, and an optional quiet dial sound.

## Highlights

- Lives entirely in the macOS menu bar
- Compares every saved city against one shared timeline
- Uses canonical timezone data, including DST and fractional offsets
- Shows working, wrapping-up, night, and weekend context at a glance
- Supports direct row reordering and contextual city actions
- Includes light, dark, and system appearance modes
- Offers keyboard and trackpad-friendly timeline control
- Stores preferences locally and makes no network requests

## Requirements

- macOS 14 Sonoma or newer
- Xcode 26 or newer

## Build from source

```bash
git clone https://github.com/taras-creates-things/Timezones.git
cd Timezones
open Timezones.xcodeproj
```

In Xcode, select the **Timezones** scheme and **My Mac**, then press **Run**. The app is menu-bar-only, so it will not appear in the Dock.

> There is not yet a signed and notarized binary release. For now, build the app from source in Xcode.

## Using the timeline

- Drag the ruler or scroll horizontally over it to shift every city together.
- The orange range measures the distance between now and the selected time.
- Click the target button to animate smoothly back to the current time.
- After focusing the ruler, use Left/Right Arrow to move by 15 minutes; hold Shift to move by one hour.
- Use the plus button to add a city and the settings button to adjust appearance, time format, home timezone, launch behavior, and sound.
- Drag city rows to reorder them, or secondary-click a row to copy, edit, move, or remove it.

## How it is built

Timezones is a native SwiftUI application with a small AppKit layer for its `NSStatusItem` and anchored `NSPanel`. Time calculations use Foundation's `TimeZone` APIs, while lightweight preferences are stored with `UserDefaults`. The project has no third-party runtime dependencies.

## Privacy

All timezone calculations and preferences stay on your Mac. Timezones has no account system, analytics, advertising, or network service.

## Tests

Run the complete test suite from Xcode, or from Terminal:

```bash
xcodebuild test \
  -project Timezones.xcodeproj \
  -scheme Timezones \
  -destination 'platform=macOS'
```

## Project status

Timezones is an early public preview (`0.1.0`). Feedback and focused contributions are welcome—please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## License

No open-source license has been selected for the application yet. The source is publicly available for viewing and evaluation, but reuse and redistribution rights are reserved.

IBM Plex Mono is distributed under the SIL Open Font License included at [`Timezones/Resources/Fonts/IBM-Plex-LICENSE.txt`](Timezones/Resources/Fonts/IBM-Plex-LICENSE.txt).
