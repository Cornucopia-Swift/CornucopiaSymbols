#if canImport(SwiftUI)
import SwiftUI

public extension Image {

    init<S: CornucopiaSymbol>(symbol: S) {
        self.init(symbol.assetName, bundle: S.bundle)
    }
}
#endif
