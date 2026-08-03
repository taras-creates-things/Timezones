# Timezones

A native macOS menu-bar utility for comparing one instant across clients and cities around the world.

## Run

1. Open `Timezones.xcodeproj` in Xcode 26 or newer.
2. Select the **Timezones** scheme and **My Mac** destination.
3. Run the app and click the clock icon in the menu bar.

The app targets macOS 14 and newer. It is a menu-bar-only app, so it does not appear in the Dock.

## Interaction

- Drag the ruler left or right, or scroll horizontally over it, to shift every timezone together.
- The shaded orange range measures the distance between now and the selected time.
- A quiet system click plays whenever the ruler crosses a 15-minute step.
- Use Left/Right Arrow after focusing the ruler; hold Shift to move by one hour.
- Click the center target button to animate the timeline back to now.
- Add cities with the plus button.
- Secondary-click a city to copy its time, edit working hours, reorder it, or remove it.
- Drag city rows to reorder them directly.
- Open Settings from the lower-left gear button; appearance changes preview immediately inside the popover.

Timezone calculations use canonical Foundation `TimeZone` identifiers and account for daylight saving transitions and fractional offsets.
