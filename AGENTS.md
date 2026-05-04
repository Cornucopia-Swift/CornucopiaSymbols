# Agent Notes

## API Surface

CornucopiaSymbols is intentionally smaller than SFSafeSymbols even though it uses
a similar typed-symbol developer experience.

Keep the stable core focused on:

- generated per-set symbol enums conforming to `CornucopiaSymbol`
- direct SwiftUI `Image(symbol:)`
- direct UIKit `UIImage(symbol:)`
- direct AppKit `NSImage(symbol:)`

Do not mirror the full SFSafeSymbols convenience surface preemptively. Add
helpers such as `Label(..., symbol:)`, `Button(..., symbol:)`, `Tab`,
`MenuBarExtra`, `ContentUnavailableView`, or AppIntents image conveniences only
after there is a concrete local use case.

Be especially careful with APIs that SFSafeSymbols implements through Apple's
SF-symbol-specific `systemName` or `systemImageName` initializers. Cornucopia
symbols live in package asset catalogs, so those APIs may not map cleanly and
must be verified per platform before becoming public API.

When adding a convenience initializer, prefer a small wrapper around existing
SwiftUI title/icon closure APIs over relying on system-image overloads.
