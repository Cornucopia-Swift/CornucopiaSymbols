import XCTest
@testable import CornucopiaSymbolsCore
@testable import CornucopiaSymbolsFeather

final class CornucopiaSymbolsCoreTests: XCTestCase {

    func testFeatherEnumExposesSymbols() {
        XCTAssertGreaterThan(Feather.allCases.count, 0, "Feather enum should be populated by the generator")
    }

    func testFeatherSetMetadata() {
        XCTAssertEqual(Feather.setName, "Feather")
        XCTAssertNotNil(Feather.bundle)
    }

    #if canImport(SwiftUI)
    func testImageInitDoesNotCrash() {
        guard let any = Feather.allCases.first else { return }
        _ = Image(symbol: any)
    }
    #endif
}

#if canImport(SwiftUI)
import SwiftUI
#endif
