import SwiftUI
import AppKit

struct SymbolDetailView: View {

    let entry: SymbolEntry?
    @State private var copied = false

    var body: some View {
        if let entry { content(for: entry).id(entry.id) } else { placeholder }
    }

    private var placeholder: some View {
        VStack { Text("No selection").foregroundStyle(.secondary).font(.caption) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func content(for entry: SymbolEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            entry.image
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.rawValue).font(.headline)
                Text("\(entry.setName) · \(entry.caseName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("Swift").font(.caption.bold()).foregroundStyle(.secondary)
                Text(entry.swiftSnippet)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                    .textSelection(.enabled)
                Button(copied ? "Copied" : "Copy snippet") { copy(entry) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            Spacer()
            Text("Drag the symbol out of the grid to save the SVG file.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func copy(_ entry: SymbolEntry) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(entry.swiftSnippet, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
    }
}
