import SwiftUI

struct SidebarView: View {

    @EnvironmentObject private var catalog: SymbolCatalog
    @Binding var selectedSet: String?
    let onInteraction: () -> Void

    init(selectedSet: Binding<String?>, onInteraction: @escaping () -> Void = {}) {
        _selectedSet = selectedSet
        self.onInteraction = onInteraction
    }

    var body: some View {
        VStack(spacing: 0) {
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

            if let selectedSetInfo {
                Divider()
                Link(destination: selectedSetInfo.homepageURL) {
                    Label(homepageDisplayText(for: selectedSetInfo.homepageURL), systemImage: "link")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(selectedSetInfo.homepageURL.absoluteString)
            }
        }
        .simultaneousGesture(TapGesture().onEnded(onInteraction))
        .frame(minWidth: 170)
    }

    private var selectedSetInfo: SymbolCatalog.SetInfo? {
        guard let selectedSet else { return nil }
        return catalog.sets.first { $0.id == selectedSet }
    }

    private func row(name: String?, displayName: String, count: Int) -> some View {
        HStack {
            Text(displayName)
            Spacer()
            Text("\(count)").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func homepageDisplayText(for url: URL) -> String {
        var text = url.absoluteString
        if text.hasPrefix("https://") {
            text.removeFirst("https://".count)
        } else if text.hasPrefix("http://") {
            text.removeFirst("http://".count)
        }
        return text.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}
