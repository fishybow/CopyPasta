//
//  CopyPastaNavigationToolbar.swift
//  CopyPasta
//

import SwiftUI

enum CopyPastaDebugMenu {
    static func seedSampleEntriesAction(store: ClipboardHistoryStore) -> (() -> Void)? {
#if DEBUG
        return { store.seedDebugSampleEntries() }
#else
        return nil
#endif
    }
}

extension View {
    func copyPastaNavigationToolbar(
        showPasteboardHelp: Binding<Bool>,
        showClearAllConfirmation: Binding<Bool>,
        onReadClipboard: @escaping () -> Void,
        onSeedDebugEntries: (() -> Void)? = nil
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        showPasteboardHelp.wrappedValue = true
                    } label: {
                        Label("Clipboard Access Help", systemImage: "questionmark.circle")
                    }
                    if let onSeedDebugEntries {
                        Button {
                            onSeedDebugEntries()
                        } label: {
                            Label("Load Sample Clips (Debug)", systemImage: "doc.text.fill")
                        }
                    }
                    Button(role: .destructive) {
                        showClearAllConfirmation.wrappedValue = true
                    } label: {
                        Label("Clear All Entries", systemImage: "trash")
                    }
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onReadClipboard()
                } label: {
                    Label("Read Clipboard Now", systemImage: "plus.circle")
                }
            }
        }
    }
}
