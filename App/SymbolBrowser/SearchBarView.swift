import SwiftUI

struct SearchBarView: View {

    @Binding var query: String
    let resultCount: Int
    @FocusState.Binding var focus: BrowserFocus?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search symbol name", text: $query)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($focus, equals: .search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text("\(resultCount)")
                .monospacedDigit()
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}
