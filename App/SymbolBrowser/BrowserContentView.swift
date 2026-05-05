import SwiftUI
import AppKit

enum BrowserFocus: Hashable {
    case sidebar
    case grid
    case search
}

struct BrowserContentView: View {

    @EnvironmentObject private var catalog: SymbolCatalog
    @State private var selectedSet: String? = nil
    @State private var query: String = ""
    @State private var selectedEntry: SymbolEntry? = nil
    @FocusState private var focus: BrowserFocus?
    @StateObject private var keyMonitor = BrowserKeyMonitor()

    var body: some View {
        HSplitView {
            SidebarView(selectedSet: $selectedSet, focus: $focus)
                .focusable()
                .focused($focus, equals: .sidebar)
                .onMoveCommand { direction in
                    navigateSidebar(direction)
                }
                .frame(minWidth: 120, idealWidth: 130, maxWidth: 160)
            VStack(spacing: 0) {
                SearchBarView(query: $query, resultCount: filtered.count, focus: $focus)
                Divider()
                HSplitView {
                    SymbolGridView(
                        entries: filtered,
                        selection: $selectedEntry,
                        focus: $focus
                    )
                        .frame(minWidth: 420)
                    SymbolDetailView(entry: selectedEntry)
                        .frame(minWidth: 160, idealWidth: 175, maxWidth: 210)
                }
            }
        }
        .onAppear {
            if selectedEntry == nil { selectedEntry = filtered.first }
            focus = .grid
            keyMonitor.onTab = toggleFocus
            keyMonitor.onPrintable = { chars in
                focus = .search
                DispatchQueue.main.async {
                    query.append(chars)
                }
            }
            keyMonitor.install()
        }
        .onDisappear {
            keyMonitor.uninstall()
        }
        .onChange(of: query) { _ in selectedEntry = filtered.first }
        .onChange(of: selectedSet) { _ in
            selectedEntry = filtered.first
        }
    }

    private func toggleFocus() {
        focus = (focus == .sidebar) ? .grid : .sidebar
    }

    private func navigateSidebar(_ direction: MoveCommandDirection) {
        let ids: [String?] = [nil] + catalog.sets.map { Optional($0.id) }
        let currentIndex = ids.firstIndex(of: selectedSet) ?? 0
        let nextIndex: Int
        switch direction {
        case .up:
            nextIndex = max(0, currentIndex - 1)
        case .down:
            nextIndex = min(ids.count - 1, currentIndex + 1)
        default:
            return
        }
        guard nextIndex != currentIndex else { return }
        selectedSet = ids[nextIndex]
    }

    private var filtered: [SymbolEntry] {
        catalog.filtered(setName: selectedSet, query: query)
    }
}

@MainActor
final class BrowserKeyMonitor: ObservableObject {

    private var monitor: Any?
    var onTab: (() -> Void)?
    var onPrintable: ((String) -> Void)?

    func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            if event.window?.firstResponder is NSText { return event }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if event.keyCode == 48 {
                guard flags.isEmpty || flags == .shift else { return event }
                self.onTab?()
                return nil
            }

            let disallowed: NSEvent.ModifierFlags = [.command, .control, .option]
            guard flags.intersection(disallowed).isEmpty else { return event }
            guard let chars = event.characters, !chars.isEmpty else { return event }
            let isPrintable = chars.unicodeScalars.allSatisfy { scalar in
                scalar.value >= 0x20 && (scalar.value < 0xE000 || scalar.value > 0xF8FF)
            }
            guard isPrintable else { return event }
            self.onPrintable?(chars)
            return nil
        }
    }

    func uninstall() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
