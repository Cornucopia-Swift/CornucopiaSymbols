import SwiftUI

@main
struct SymbolBrowserApp: App {

    @StateObject private var catalog = SymbolCatalog.shared

    var body: some Scene {
        MenuBarExtra("CornucopiaSymbols", systemImage: "square.grid.3x3.fill") {
            BrowserContentView()
                .environmentObject(catalog)
                .frame(width: 720, height: 520)
        }
        .menuBarExtraStyle(.window)
    }
}
