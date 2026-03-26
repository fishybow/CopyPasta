//
//  StarredEntriesTabView.swift
//  CopyPasta
//

import SwiftData
import SwiftUI

struct StarredEntriesTabView: View {
    let store: ClipboardHistoryStore
    let flashCopiedID: PersistentIdentifier?
    @Binding var fullContentDetail: FullContentDetail?
    @Binding var showPasteboardHelp: Bool
    @Binding var showClearAllConfirmation: Bool
    @Binding var starredTabPrimed: Bool
    let onCopy: (ClipboardEntry) -> Void

    var body: some View {
        NavigationStack {
            ClipboardEntriesListView(
                entries: store.starredEntries,
                loadNextPage: { store.loadNextStarredPage() },
                store: store,
                flashCopiedID: flashCopiedID,
                onCopy: onCopy,
                onViewFullContent: { fullContentDetail = FullContentDetail(from: $0) }
            )
            .navigationTitle("Starred")
            .copyPastaNavigationToolbar(
                showPasteboardHelp: $showPasteboardHelp,
                showClearAllConfirmation: $showClearAllConfirmation,
                onReadClipboard: { store.capturePasteboardIfChanged() },
                onSeedDebugEntries: CopyPastaDebugMenu.seedSampleEntriesAction(store: store)
            )
            .onAppear {
                if !starredTabPrimed {
                    starredTabPrimed = true
                    store.loadInitialStarred()
                }
            }
        }
    }
}
