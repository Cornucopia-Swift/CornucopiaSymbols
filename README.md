# CornucopiaSymbols

> ⚠️ **Work in progress.** API surface, target names, and the SymbolBrowser app
> are subject to change before a 1.0 release. No tagged release yet — pin to a
> commit if you depend on this.

A typed, autocompletable Swift API for ~21,000 open-source icons sourced from
[opensymbols.dev](https://opensymbols.dev) — modelled after the developer
experience of [SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols),
but for icon sets that aren't shipped by Apple.

```swift
import SwiftUI
import CornucopiaSymbolsLucide

Image(symbol: Lucide.heart)
    .foregroundStyle(.pink)
    .font(.title)
```

A companion macOS menu-bar app, **SymbolBrowser**, lets you search across all
sets, copy a Swift snippet, and drag the SVG out into Finder.

## Bundled symbol sets

Each set is its own SwiftPM library target — apps pay only for what they import.

| Library                              | Symbols | License      |
| ------------------------------------ | ------: | ------------ |
| `CornucopiaSymbolsFeather`           |     287 | MIT          |
| `CornucopiaSymbolsHeroicons`         |     648 | MIT          |
| `CornucopiaSymbolsLucide`            |   1,557 | ISC          |
| `CornucopiaSymbolsFontAwesome`       |   2,059 | CC BY 4.0    |
| `CornucopiaSymbolsRemix`             |   3,058 | Apache 2.0   |
| `CornucopiaSymbolsTabler`            |   5,880 | MIT          |
| `CornucopiaSymbolsPictogrammers`     |   7,447 | Apache 2.0   |
| **Total**                            | **20,936** |          |

Each set retains its original license. The full text of every bundled
license ships inside the corresponding SwiftPM target as `LICENSE.txt`, and
[`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md) at the repo root indexes
all of them in one place. The wrapper code is MIT-licensed (see `LICENSE`).

> **Font Awesome users:** the Free icons are CC BY 4.0, which requires
> attribution. If you ship Font Awesome icons in a product, credit Font Awesome
> in your About / Acknowledgements screen.

## Installation (SwiftPM)

```swift
.package(url: "https://github.com/CornucopiaSwift/CornucopiaSymbols.git", branch: "master"),
```

In your target's `dependencies`:

```swift
.product(name: "CornucopiaSymbolsLucide", package: "CornucopiaSymbols"),
.product(name: "CornucopiaSymbolsFeather", package: "CornucopiaSymbols"),
// …only the sets you actually need
```

## Usage

### SwiftUI

```swift
import SwiftUI
import CornucopiaSymbolsLucide

Image(symbol: Lucide.alignCenterHorizontal)
    .resizable()
    .scaledToFit()
    .frame(width: 24, height: 24)
```

### UIKit

```swift
import UIKit
import CornucopiaSymbolsHeroicons

let imageView = UIImageView(image: UIImage(symbol: Heroicons.bell))
```

### AppKit

```swift
import AppKit
import CornucopiaSymbolsFeather

let img = NSImage(symbol: Feather.alertTriangle)
```

### API scope

CornucopiaSymbols intentionally keeps the public convenience surface narrow for
now. The stable core is the typed symbol enums plus direct `Image`, `UIImage`,
and `NSImage` constructors. SFSafeSymbols also offers conveniences for views such
as `Label`, `Button`, `Tab`, `MenuBarExtra`, and `ContentUnavailableView`, but we
only add those here once a real call site needs them.

Some SFSafeSymbols APIs wrap SF-symbol-specific system image initializers and do
not map cleanly to package asset catalogs. Those should be verified on the target
platform before being mirrored.

## Naming

Upstream filenames use `kebab-case` (and Font Awesome adds `.fill` suffixes for
solid variants). The generator translates them to Swift identifiers:

| Upstream filename          | Swift case                  | Raw value                   |
| -------------------------- | --------------------------- | --------------------------- |
| `heart.svg`                | `heart`                     | `"heart"`                   |
| `align-center-horizontal.svg` | `alignCenterHorizontal`  | `"align-center-horizontal"` |
| `house.fill.svg`           | `houseFill`                 | `"house.fill"`              |
| `2fa.svg`                  | `_2fa`                      | `"2fa"`                     |
| `repeat.svg`               | `` `repeat` ``              | `"repeat"`                  |

## SymbolBrowser (menu-bar app)

A macOS 13+ menu-bar utility for searching, previewing, copying snippets, and
dragging SVGs out.

```sh
# Build a real .app bundle (LSUIElement = true, no Dock icon)
Scripts/build-app.sh release
open ./SymbolBrowser.app
```

Or, for a quick sanity check during development:

```sh
swift run SymbolBrowser
```

## Refreshing from upstream

```sh
Scripts/sync-symbols.sh   # re-clone Vendor/open-symbols
Scripts/generate.py       # regenerate every Sources/CornucopiaSymbols<Set>/
swift test                # smoke check
```

`Vendor/` is gitignored — only the generated `Sources/` and `Resources/` end
up in the repo.

## Limitations inherited from upstream

- **No weight variations.** Symbols render at a single weight regardless of
  `.font(.bold)`. The upstream `buzap/open-symbols` project is working on it.
- **Single-layer rendering.** Hierarchical / palette / multicolor rendering
  modes that depend on per-layer SF Symbol metadata aren't represented in the
  current upstream conversion.

## Acknowledgements

- [opensymbols.dev](https://opensymbols.dev) and the
  [buzap/open-symbols](https://github.com/buzap/open-symbols) repository for
  doing the SF-Symbols conversion work.
- Each individual icon set's authors — see the per-set `ATTRIBUTION.md`.
- [SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols) for the API
  shape this project mimics.

## License

MIT for the wrapper code (see `LICENSE`). Each bundled symbol set keeps its
original license.
