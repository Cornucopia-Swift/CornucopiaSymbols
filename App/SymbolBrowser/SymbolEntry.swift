import Foundation
import SwiftUI
import CornucopiaSymbolsCore

/// Type-erased view of one symbol from any set, with everything the UI needs
/// pre-resolved at catalog-build time.
struct SymbolEntry: Identifiable, Hashable {

    let id: String              // "<setName>.<rawValue>"
    let setName: String         // e.g. "Lucide"
    let caseName: String        // e.g. "alignCenterHorizontal"
    let rawValue: String        // e.g. "align-center-horizontal" (== asset name)
    let bundle: Bundle

    var image: Image { Image(rawValue, bundle: bundle) }

    var swiftSnippet: String {
        // If the case name needed backticks in the generated enum, the user has
        // to type them at the call site too.
        let casePart = needsBackticks(caseName) ? "`\(caseName)`" : caseName
        return "Image(symbol: \(setName).\(casePart))"
    }

    var svgURL: URL? {
        bundle.url(
            forResource: "\(rawValue).svg",
            withExtension: nil,
            subdirectory: "\(setName).xcassets/\(rawValue).symbolset"
        )
    }
}

private let swiftKeywords: Set<String> = [
    "class", "struct", "enum", "protocol", "func", "var", "let",
    "if", "else", "for", "while", "do", "switch", "case", "default",
    "break", "continue", "return", "throw", "throws", "rethrows",
    "import", "init", "deinit", "self", "super", "true", "false", "nil",
    "any", "some", "where", "as", "is", "in", "operator", "static",
    "public", "private", "fileprivate", "internal", "open", "extension",
    "typealias", "associatedtype", "subscript", "guard", "defer", "repeat",
    "fallthrough", "lazy", "weak", "unowned", "convenience", "dynamic",
    "final", "override", "required", "indirect", "mutating", "nonmutating",
    "optional", "set", "get",
]

private func needsBackticks(_ name: String) -> Bool {
    swiftKeywords.contains(name)
}
