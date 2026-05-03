import Foundation
import Combine
import CornucopiaSymbolsCore
import CornucopiaSymbolsFeather
import CornucopiaSymbolsHeroicons
import CornucopiaSymbolsLucide
import CornucopiaSymbolsFontAwesome
import CornucopiaSymbolsRemix
import CornucopiaSymbolsTabler
import CornucopiaSymbolsPictogrammers

/// All symbols across all bundled sets, indexed once at app launch.
@MainActor
final class SymbolCatalog: ObservableObject {

    static let shared = SymbolCatalog()

    struct SetInfo: Identifiable, Hashable {
        let id: String          // setName
        let displayName: String
        let count: Int
    }

    let sets: [SetInfo]
    let entries: [SymbolEntry]                          // flat list, all sets
    let entriesBySet: [String: [SymbolEntry]]           // setName → entries

    private init() {
        var allEntries: [SymbolEntry] = []
        var bySet: [String: [SymbolEntry]] = [:]
        var infos: [SetInfo] = []

        func ingest<S: CornucopiaSymbol>(_ type: S.Type, displayName: String) {
            let cases = Array(type.allCases)
            let entries = cases.map { c in
                SymbolEntry(
                    id: "\(type.setName).\(c.rawValue)",
                    setName: type.setName,
                    caseName: caseNameFor(c),
                    rawValue: c.rawValue,
                    bundle: type.bundle
                )
            }
            allEntries.append(contentsOf: entries)
            bySet[type.setName] = entries
            infos.append(.init(id: type.setName, displayName: displayName, count: entries.count))
        }

        ingest(Feather.self,        displayName: "Feather")
        ingest(Heroicons.self,      displayName: "Heroicons")
        ingest(Lucide.self,         displayName: "Lucide")
        ingest(FontAwesome.self,    displayName: "Font Awesome")
        ingest(Remix.self,          displayName: "Remix")
        ingest(Tabler.self,         displayName: "Tabler")
        ingest(Pictogrammers.self,  displayName: "Pictogrammers")

        self.entries = allEntries
        self.entriesBySet = bySet
        self.sets = infos
    }

    /// Total symbol count across all bundled sets.
    var totalCount: Int { entries.count }

    /// Filter by optional set + optional case-insensitive substring search.
    func filtered(setName: String?, query: String) -> [SymbolEntry] {
        let pool: [SymbolEntry]
        if let setName, let scoped = entriesBySet[setName] {
            pool = scoped
        } else {
            pool = entries
        }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return pool }
        let needle = trimmed.lowercased()
        return pool.filter { $0.rawValue.lowercased().contains(needle) }
    }
}

/// Best-effort: reconstruct the camelCase case name from rawValue. The generator
/// uses the same rule, so this stays in lock-step (no metadata round-trip needed).
private func caseNameFor<S: CornucopiaSymbol>(_ c: S) -> String {
    let raw = c.rawValue
    let parts = raw.split(whereSeparator: { "-_.".contains($0) }).map(String.init)
    guard let first = parts.first else { return raw }
    let head = first.lowercased()
    let tail = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined()
    var name = head + tail
    if let initial = name.first, initial.isNumber {
        name = "_" + name
    }
    return name
}
