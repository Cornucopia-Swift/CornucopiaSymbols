import SwiftUI

struct SymbolGridView: View {

    let entries: [SymbolEntry]
    @Binding var selection: SymbolEntry?
    @FocusState.Binding var focus: BrowserFocus?
    @State private var scrollTargetID: SymbolEntry.ID?

    private let columns = [GridItem(.adaptive(minimum: 92, maximum: 110), spacing: 6)]

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(entries) { entry in
                            SymbolGridCell(entry: entry, isSelected: entry == selection)
                                .id(entry.id)
                                .onTapGesture { select(entry) }
                        }
                    }
                    .padding(8)
                }
                .contentShape(Rectangle())
                .focusable()
                .focused($focus, equals: .grid)
                .onTapGesture { focus = .grid }
                .onMoveCommand { direction in
                    moveSelection(direction, columnCount: columnCount(for: geometry.size.width))
                }
                .onChange(of: scrollTargetID) { targetID in
                    guard let targetID else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        scrollProxy.scrollTo(targetID, anchor: nil)
                    }
                    scrollTargetID = nil
                }
            }
        }
    }

    private func select(_ entry: SymbolEntry) {
        selection = entry
        scrollTargetID = entry.id
        focus = .grid
    }

    private func moveSelection(_ direction: MoveCommandDirection, columnCount: Int) {
        guard !entries.isEmpty else { return }

        let currentIndex = selection.flatMap { entries.firstIndex(of: $0) } ?? 0
        let targetIndex: Int

        switch direction {
        case .left:
            targetIndex = currentIndex - 1
        case .right:
            targetIndex = currentIndex + 1
        case .up:
            targetIndex = currentIndex - columnCount
        case .down:
            targetIndex = currentIndex + columnCount
        default:
            return
        }

        let clampedIndex = min(max(targetIndex, 0), entries.count - 1)
        guard clampedIndex != currentIndex else { return }

        select(entries[clampedIndex])
    }

    private func columnCount(for width: CGFloat) -> Int {
        let horizontalPadding: CGFloat = 16
        let minimumColumnWidth: CGFloat = 92
        let columnSpacing: CGFloat = 6
        let availableWidth = max(width - horizontalPadding, minimumColumnWidth)
        return max(1, Int((availableWidth + columnSpacing) / (minimumColumnWidth + columnSpacing)))
    }
}
