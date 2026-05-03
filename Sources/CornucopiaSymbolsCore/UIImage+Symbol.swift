#if canImport(UIKit)
import UIKit

public extension UIImage {

    convenience init?<S: CornucopiaSymbol>(symbol: S, with configuration: UIImage.Configuration? = nil) {
        self.init(named: symbol.assetName, in: S.bundle, with: configuration)
    }
}
#endif
