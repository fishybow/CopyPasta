//
//  ClipboardEntriesListView.swift
//  CopyPasta
//

import SwiftData
import SwiftUI

struct ClipboardEntriesListView: View {
    let entries: [ClipboardEntry]
    let loadNextPage: () -> Void
    let store: ClipboardHistoryStore
    let flashCopiedID: PersistentIdentifier?
    let onCopy: (ClipboardEntry) -> Void
    let onViewFullContent: (ClipboardEntry) -> Void

    var body: some View {
        List {
            ForEach(entries) { entry in
                ClipboardEntryRow(
                    entry: entry,
                    store: store,
                    isCopiedFlash: flashCopiedID == entry.persistentModelID,
                    onCopy: { onCopy(entry) },
                    onViewFullContent: { onViewFullContent(entry) }
                )
                .onAppear {
                    if entry.persistentModelID == entries.last?.persistentModelID {
                        loadNextPage()
                    }
                }
            }
        }
        .listStyle(.plain)
        .contentMargins(.horizontal, 0, for: .scrollContent)
    }
}
