import AppKit
import SwiftUI

struct ZoneRowView: View {
    let zone: TrackedZone
    let selectedDate: Date
    let homeTimeZone: TimeZone
    let uses24HourTime: Bool
    var isHome = false
    var canMoveUp = false
    var canMoveDown = false
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onEdit: (() -> Void)?
    var onRemove: (() -> Void)?

    private var status: WorkStatus {
        WorkStatusEngine.status(
            for: selectedDate,
            in: zone.timeZone,
            schedule: zone.workSchedule
        )
    }

    private var time: String {
        TimeEngine.timeString(
            for: selectedDate,
            in: zone.timeZone,
            uses24HourTime: uses24HourTime
        )
    }

    private var metadata: String {
        if isHome {
            return "YOUR TIME · \(TimeEngine.dateString(for: selectedDate, in: zone.timeZone))"
        }

        let offset = TimeEngine.relativeOffsetString(
            for: selectedDate,
            zone: zone.timeZone,
            relativeTo: homeTimeZone
        )
        let abbreviation = TimeEngine.abbreviation(for: selectedDate, in: zone.timeZone)
        if let day = TimeEngine.relativeDayLabel(for: selectedDate, zone: zone.timeZone, relativeTo: homeTimeZone) {
            return "\(offset) / \(abbreviation) · \(day)"
        }
        return "\(offset) / \(abbreviation)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(metadata)
                    .lineLimit(1)
                Spacer(minLength: 8)
                StatusLabel(status: status)
            }
            .font(AppTypography.secondary(size: 10, relativeTo: .caption2))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(zone.label)
                    .font(AppTypography.primary(size: 20))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Text(time)
                    .font(AppTypography.primary(size: 20))
                    .monospacedDigit()
                    .foregroundStyle(status == .night || status == .weekend ? .secondary : .primary)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.16), value: time)
            }
        }
        .padding(DesignTokens.cellInset)
        .frame(maxWidth: .infinity, minHeight: DesignTokens.rowHeight, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(zone.label)
        .accessibilityValue("\(time), \(metadata), \(status.label)")
        .contextMenu {
            if !isHome {
                Button("Copy Time", systemImage: "doc.on.doc") {
                    copyTime()
                }

                Button("Edit…", systemImage: "pencil", action: onEdit ?? {})

                Divider()

                Button("Move Up", systemImage: "arrow.up", action: onMoveUp ?? {})
                    .disabled(!canMoveUp)
                Button("Move Down", systemImage: "arrow.down", action: onMoveDown ?? {})
                    .disabled(!canMoveDown)

                Divider()

                Button("Remove", systemImage: "trash", role: .destructive, action: onRemove ?? {})
            }
        }
    }

    private func copyTime() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(zone.label) — \(time)", forType: .string)
    }
}

private struct StatusLabel: View {
    let status: WorkStatus

    var body: some View {
        HStack(spacing: 4) {
            Text(status.label)
            Image(systemName: status.systemImage)
                .font(.system(size: status == .working || status == .wrappingUp ? 8 : 10))
                .foregroundStyle(status.color)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
