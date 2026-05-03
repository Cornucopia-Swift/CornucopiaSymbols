#if canImport(AppKit)
import AppKit

public extension NSImage {

    convenience init?<S: CornucopiaSymbol>(symbol: S) {
        guard let cgImage = S.bundle.image(forResource: NSImage.Name(symbol.assetName))?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        self.init(cgImage: cgImage, size: .zero)
    }
}

public extension Bundle {

    func cornucopiaSymbolImage<S: CornucopiaSymbol>(_ symbol: S) -> NSImage? {
        S.bundle.image(forResource: NSImage.Name(symbol.assetName))
    }
}
#endif
