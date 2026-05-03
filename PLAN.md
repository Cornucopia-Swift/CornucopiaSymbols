# CornucopiaSymbols — Implementation Plan

A Swift Package providing typed, autocompletable access to ~20,000 open-source icons from
[opensymbols.dev](https://opensymbols.dev) (the buzap/open-symbols repo), plus a macOS
menu-bar browser app. Models itself on [SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols)
in spirit, but for non-Apple icon sets.

## Decisions (locked in)

- **Packaging:** one SPM target per symbol set. Apps pay only for what they import.
- **API shape:** per-set enums, e.g. `Image(symbol: Lucide.heart)`. Each enum conforms to
  a shared `CornucopiaSymbol` protocol.
- **Source sync:** vendored snapshot + reproducible sync script. The script regenerates
  enums and asset catalogs from a fresh upstream clone.
- **App scope:** click-to-copy Swift snippet + drag-out as SVG. (No PNG/license views in v1.)

## Upstream facts

| Set                              | Count  | License      | Notes                                                |
| -------------------------------- | -----: | ------------ | ---------------------------------------------------- |
| Feather                          |    287 | MIT          |                                                      |
| Heroicons                        |    648 | MIT          |                                                      |
| Lucide                           |  1,557 | ISC          |                                                      |
| Font Awesome (Free)              |  2,059 | CC BY 4.0    | Solid icons get `.fill` suffix (SF Symbols-style)    |
| Remix                            |  3,058 | Apache 2.0   |                                                      |
| Tabler                           |  5,880 | MIT          | ~126 MB                                              |
| Pictogrammers Material Design    |  7,447 | Apache 2.0   | ~123 MB                                              |
| **Total**                        | 20,936 |              | ~390 MB of SVG                                       |

All SVGs are real SF Symbols templates (full weight/scale grid). They drop into an
`.xcassets` catalog as Symbol Image Sets and render through `Image(_:bundle:)` /
`UIImage(named:in:with:)` / `NSImage(named:)`.

Note from upstream: weight variations are not yet implemented. Symbols render as a
single weight regardless of `.font(.bold)` etc. — limitation we inherit.

## Repository layout

```
CornucopiaSymbols/
├── Package.swift
├── README.md
├── LICENSE                            # MIT (our wrapper code)
├── PLAN.md
├── .gitignore                         # ignore Vendor/, build/, etc.
├── Vendor/                            # workspace; not committed
│   └── open-symbols/                  # cloned by Scripts/sync-symbols.sh
├── Scripts/
│   ├── sync-symbols.sh                # clone upstream into Vendor/
│   └── generate.py                    # Vendor/ → Sources/.../Generated + .xcassets
├── Sources/
│   ├── CornucopiaSymbolsCore/
│   │   ├── CornucopiaSymbol.swift     # protocol
│   │   ├── Image+Symbol.swift         # SwiftUI Image init
│   │   ├── UIImage+Symbol.swift       # iOS/tvOS/watchOS/visionOS
│   │   └── NSImage+Symbol.swift       # macOS
│   ├── CornucopiaSymbolsFeather/
│   │   ├── Feather.swift              # generated enum
│   │   └── Resources/Feather.xcassets/
│   ├── CornucopiaSymbolsHeroicons/
│   ├── CornucopiaSymbolsLucide/
│   ├── CornucopiaSymbolsFontAwesome/
│   ├── CornucopiaSymbolsRemix/
│   ├── CornucopiaSymbolsTabler/
│   └── CornucopiaSymbolsPictogrammers/
├── Tests/
│   └── CornucopiaSymbolsCoreTests/
└── App/
    └── SymbolBrowser/                 # macOS menu-bar app (SwiftPM executable)
        ├── SymbolBrowserApp.swift
        ├── MenuBarRoot.swift
        ├── BrowserView.swift          # search + grid
        ├── SidebarView.swift          # set filter
        ├── SymbolGridCell.swift
        ├── SymbolDetailPanel.swift    # snippet copy / drag
        ├── SymbolCatalog.swift        # in-memory index of all symbols
        └── DragRepresentable.swift
```

One file per view (per CLAUDE.md). One file per generated enum.

## Repo size strategy

The committed `.xcassets` directories together are ~390 MB. Options:

1. **Ship as-is.** Users `git clone` a 400 MB repo. Acceptable for a one-time clone;
   SPM resolves a tag tarball, which is comparable.
2. **Git LFS for `*.svg` under Sources/**. Smaller working clone, but requires LFS at
   clone time and SPM does *not* fetch LFS objects automatically — fatal for SPM.
3. **Split into multiple repos** (one per set). Cleanest size-wise, ugliest from a
   "this is one project" standpoint.

**Decision:** ship as-is for v1. Tag releases get distributed as tarballs through SPM,
which avoids LFS issues. If size becomes painful, we revisit splitting.

## Generation: `Scripts/generate.py`

Per set, walks `Vendor/open-symbols/<set>/symbols/*.svg` and emits:

1. **Asset catalog** at `Sources/CornucopiaSymbols<Set>/Resources/<Set>.xcassets/`:
   - Top-level `Contents.json` (`{"info": {"version": 1, "author": "xcode"}}`)
   - One folder per symbol: `<symbol>.symbolset/` containing `Contents.json` and the SVG.
   - SF Symbols Symbol Image Sets reference an SVG via:
     ```json
     {
       "info": { "version": 1, "author": "xcode" },
       "symbols": [ { "filename": "heart.svg", "idiom": "universal" } ]
     }
     ```

2. **Swift enum** at `Sources/CornucopiaSymbols<Set>/<Set>.swift`:
   ```swift
   public enum Lucide: String, CornucopiaSymbol {
       public static let bundle = Bundle.module
       case heart                              // raw "heart"
       case alignCenterHorizontal              // raw "align-center-horizontal"
       case `class`                            // backticked Swift keyword
       case _2faIcon = "2fa-icon"              // leading-digit fallback
       case houseFill = "house.fill"           // Font Awesome dotted variant
   }
   ```

   **Naming rules** (kebab-case → camelCase, with collision/keyword handling):
   - `foo-bar` → `fooBar`
   - `class` (Swift keyword) → `` `class` ``
   - `2fa` (leading digit) → `_2fa`
   - `house.fill` → `houseFill`, raw value `"house.fill"` (asset name with dot)
   - On generated case-name collision (post-camelcasing), suffix with `_2`, `_3`, …

   **Note on dotted asset names:** Xcode treats `.` in asset names as folder separators
   in Symbol Image Sets, which Font Awesome upstream already accommodates. We preserve
   the upstream filename verbatim as the raw value.

## Core API

```swift
public protocol CornucopiaSymbol: RawRepresentable where RawValue == String {
    static var bundle: Bundle { get }
}

#if canImport(SwiftUI)
public extension Image {
    init<S: CornucopiaSymbol>(symbol: S) {
        self.init(symbol.rawValue, bundle: S.bundle)
    }
}
#endif

#if canImport(UIKit)
public extension UIImage {
    convenience init?<S: CornucopiaSymbol>(symbol: S) {
        self.init(named: symbol.rawValue, in: S.bundle, with: nil)
    }
}
#endif

#if canImport(AppKit)
public extension NSImage {
    convenience init?<S: CornucopiaSymbol>(symbol: S) {
        self.init(named: symbol.rawValue, in: S.bundle)
    }
}
#endif
```

Usage:

```swift
import SwiftUI
import CornucopiaSymbolsLucide

Image(symbol: Lucide.heart)
    .foregroundStyle(.pink)
    .font(.title)
```

## Menu-bar app

- `MenuBarExtra` SwiftUI app, `.window` style (popover-like detached window).
- **Sidebar:** "All", then one row per symbol set with the count.
- **Top bar:** search field. Case-insensitive substring match against symbol name.
- **Grid:** `LazyVGrid` of cells; each shows the rendered symbol + its name.
- **Detail panel** (right or below): selected symbol enlarged + a copy-the-snippet
  button (`Image(symbol: Lucide.heart)`). The cell is also draggable — drag yields
  the SVG file URL via `NSItemProvider` so it drops into Finder/Mail/etc.
- **Index source:** the app links *all* per-set targets and walks each set's enum
  via `CaseIterable` to build a flat in-memory catalog at launch.

The app is a SwiftPM executable, not an Xcode project, so building is `swift run
SymbolBrowser`. (User can wrap in an Xcode project later if they want a real `.app`
bundle for distribution.)

## Implementation order

1. **Skeleton** — `Package.swift` with Core + one set (Feather, smallest) + tests.
2. **Sync + generate scripts.** Run end-to-end on Feather. Verify a sample symbol
   renders in a tiny SwiftUI test.
3. **Roll out remaining sets** — re-run the generator with all sets.
4. **Menu-bar app** scaffold, then catalog, then search, then grid, then drag/copy.
5. **README** with usage, attribution table, and a `Scripts/sync-symbols.sh`
   refresh procedure for upstream updates.

## Open questions / future work

- Weight variations: blocked on upstream (SymbolKit.app maturity).
- Hierarchical / palette / multicolor rendering: depends on whether upstream emits
  the layer hierarchy in the SVG. Worth probing, but not v1 scope.
- iOS/macOS preview Swift Playground showcasing the catalog — nice-to-have.
