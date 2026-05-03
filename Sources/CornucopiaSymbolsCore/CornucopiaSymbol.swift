import Foundation

public protocol CornucopiaSymbol: RawRepresentable, CaseIterable, Hashable where RawValue == String {

    static var bundle: Bundle { get }

    static var setName: String { get }
}

public extension CornucopiaSymbol {

    var assetName: String { rawValue }

    /// URL of the underlying SF-Symbols template SVG inside the resource bundle.
    ///
    /// Returns `nil` when the asset catalog has been compiled to `Assets.car`
    /// (typical for Xcode-built iOS/macOS apps), in which case the SVG is no
    /// longer present as a separate file. Always available when the package is
    /// consumed via `swift build` (e.g. SwiftPM executables and tests).
    var svgURL: URL? {
        Self.bundle.url(
            forResource: "\(rawValue).svg",
            withExtension: nil,
            subdirectory: "\(Self.setName).xcassets/\(rawValue).symbolset"
        )
    }
}
