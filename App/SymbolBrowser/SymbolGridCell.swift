import SwiftUI
import UniformTypeIdentifiers

struct SymbolGridCell: View {

    let entry: SymbolEntry
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            entry.image
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(.primary)
            Text(entry.rawValue)
                .font(.system(size: 10))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
        }
        .frame(width: 96, height: 70)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .help(entry.rawValue)
        .onDrag { dragProvider(for: entry) }
    }

    private func dragProvider(for entry: SymbolEntry) -> NSItemProvider {
        guard let url = entry.svgURL else {
            // Fallback: drag the snippet text instead.
            return NSItemProvider(object: entry.swiftSnippet as NSString)
        }
        return NSItemProvider(contentsOf: url) ?? NSItemProvider(object: url as NSURL)
    }
}
