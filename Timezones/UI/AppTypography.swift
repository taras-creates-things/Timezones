import CoreText
import SwiftUI

enum AppTypography {
    private static let plexRegularName = "IBMPlexMono"
    private static let plexMediumName = "IBMPlexMono-Medm"
    private static let bundledFontFiles = [
        "IBMPlexMono-Regular",
        "IBMPlexMono-Medium"
    ]

    static func registerBundledFonts(in bundle: Bundle = .main) {
        for resourceName in bundledFontFiles {
            let url = bundle.url(
                forResource: resourceName,
                withExtension: "ttf",
                subdirectory: "Fonts"
            ) ?? bundle.url(forResource: resourceName, withExtension: "ttf")

            guard let url else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func primary(
        size: CGFloat,
        weight: Font.Weight = .regular
    ) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func secondary(
        size: CGFloat,
        weight: Font.Weight = .medium,
        relativeTo textStyle: Font.TextStyle = .caption
    ) -> Font {
        .custom(
            weight == .regular ? plexRegularName : plexMediumName,
            size: size,
            relativeTo: textStyle
        )
    }
}
