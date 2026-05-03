import Foundation

/// Locate a SwiftPM-style resource bundle, searching the standard `.app` layout
/// first.
///
/// SwiftPM's auto-generated `Bundle.module` accessor only looks next to the
/// host executable (`Bundle.main.bundleURL`) — which is correct for
/// `swift run` invocations, where `Bundle.main.bundleURL` is the executable's
/// directory, but is wrong when the executable has been wrapped into an `.app`
/// bundle (where `Bundle.main.bundleURL` is the `.app` itself, and resources
/// live in `Contents/Resources/`). It also falls back to a hardcoded absolute
/// `.build/...` path baked in at compile time, which resolves on the developer
/// machine to *uncompiled* asset catalogs and silently masks the bug.
///
/// This resolver checks the standard `.app` location first, then the
/// `swift run` location, and only falls through to the SwiftPM-baked
/// `fallback` when neither exists.
public func resolveCornucopiaBundle(named bundleName: String, fallback: Bundle) -> Bundle {
    let leaf = "\(bundleName).bundle"
    let candidates: [URL?] = [
        Bundle.main.resourceURL?.appendingPathComponent(leaf),
        Bundle.main.bundleURL.appendingPathComponent(leaf),
    ]
    for url in candidates.compactMap({ $0 }) where FileManager.default.fileExists(atPath: url.path) {
        if let bundle = Bundle(url: url) {
            return bundle
        }
    }
    return fallback
}
