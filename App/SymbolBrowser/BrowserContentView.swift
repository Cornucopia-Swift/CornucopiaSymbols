import SwiftUI

struct BrowserContentView: View {

    @EnvironmentObject private var catalog: SymbolCatalog
    @State private var selectedSet: String? = nil
    @State private var query: String = ""
    @State private var selectedEntry: SymbolEntry? = nil

    var body: some View {
        HSplitView {
            SidebarView(selectedSet: $selectedSet)
                .frame(minWidth: 120, idealWidth: 130, maxWidth: 160)
            VStack(spacing: 0) {
                SearchBarView(query: $query, resultCount: filtered.count)
                Divider()
                HSplitView {
                    SymbolGridView(entries: filtered, selection: $selectedEntry)
                        .frame(minWidth: 420)
                    SymbolDetailView(entry: selectedEntry)
                        .frame(minWidth: 160, idealWidth: 175, maxWidth: 210)
                }
            }
        }
        .onAppear {
            if selectedEntry == nil { selectedEntry = filtered.first }
        }
        .onChange(of: query) { _ in selectedEntry = filtered.first }
        .onChange(of: selectedSet) { _ in selectedEntry = filtered.first }
    }

    private var filtered: [SymbolEntry] {
        catalog.filtered(setName: selectedSet, query: query)
    }
}
