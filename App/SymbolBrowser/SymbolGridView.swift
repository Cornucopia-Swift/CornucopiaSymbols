import SwiftUI

struct SymbolGridView: View {

    let entries: [SymbolEntry]
    @Binding var selection: SymbolEntry?

    private let columns = [GridItem(.adaptive(minimum: 92, maximum: 110), spacing: 6)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(entries) { entry in
                    SymbolGridCell(entry: entry, isSelected: entry == selection)
                        .onTapGesture { selection = entry }
                }
            }
            .padding(8)
        }
    }
}
