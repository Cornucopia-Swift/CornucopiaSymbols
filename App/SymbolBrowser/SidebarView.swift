import SwiftUI

struct SidebarView: View {

    @EnvironmentObject private var catalog: SymbolCatalog
    @Binding var selectedSet: String?

    var body: some View {
        List(selection: $selectedSet) {
            Section("All") {
                row(name: nil, displayName: "All sets", count: catalog.totalCount)
                    .tag(String?.none)
            }
            Section("Sets") {
                ForEach(catalog.sets) { set in
                    row(name: set.id, displayName: set.displayName, count: set.count)
                        .tag(Optional(set.id))
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 170)
    }

    private func row(name: String?, displayName: String, count: Int) -> some View {
        HStack {
            Text(displayName)
            Spacer()
            Text("\(count)").font(.caption).foregroundStyle(.secondary)
        }
    }
}
