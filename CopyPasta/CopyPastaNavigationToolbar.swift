//
//  CopyPastaNavigationToolbar.swift
//  CopyPasta
//

import SwiftUI

extension View {
    func copyPastaNavigationToolbar(
        showPasteboardHelp: Binding<Bool>,
        showClearAllConfirmation: Binding<Bool>,
        onReadClipboard: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        showPasteboardHelp.wrappedValue = true
                    } label: {
                        Label("Clipboard Access Help", systemImage: "questionmark.circle")
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
                    Label("Read Clipboard Now", systemImage: "arrow.down.doc")
                }
            }
        }
    }
}
