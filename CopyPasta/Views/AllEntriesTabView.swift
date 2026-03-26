//
//  AllEntriesTabView.swift
//  CopyPasta
//

import SwiftData
import SwiftUI

struct AllEntriesTabView: View {
    let store: ClipboardHistoryStore
    let flashCopiedID: PersistentIdentifier?
    @Binding var fullContentDetail: FullContentDetail?
    @Binding var showPasteboardHelp: Bool
    @Binding var showClearAllConfirmation: Bool
    let onCopy: (ClipboardEntry) -> Void

    var body: some View {
        NavigationStack {
            ClipboardEntriesListView(
                entries: store.entries,
                loadNextPage: { store.loadNextPage() },
                store: store,
                flashCopiedID: flashCopiedID,
                onCopy: onCopy,
                onViewFullContent: { fullContentDetail = FullContentDetail(from: $0) }
            )
            .navigationTitle("CopyPasta")
            .copyPastaNavigationToolbar(
                showPasteboardHelp: $showPasteboardHelp,
                showClearAllConfirmation: $showClearAllConfirmation,
                onReadClipboard: { store.capturePasteboardIfChanged() }
            )
        }
    }
}
