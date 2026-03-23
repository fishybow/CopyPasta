//
//  ClipboardEntryRow.swift
//  CopyPasta
//

import SwiftData
import SwiftUI

struct ClipboardEntryRow: View {
    @Bindable var entry: ClipboardEntry
    let store: ClipboardHistoryStore
    let isCopiedFlash: Bool
    let onCopy: () -> Void
    let onViewFullContent: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.text)
                    .font(.body)
                    .lineLimit(4)
                HStack(spacing: 6) {
                    Text(entry.capturedAt, format: .dateTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if entry.isStarred {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Starred")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isCopiedFlash {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: isCopiedFlash)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(isCopiedFlash ? 0.14 : 0))
        )
        .contextMenu {
            Button {
                onViewFullContent()
            } label: {
                Label("View Full Content", systemImage: "doc.text")
            }
            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            if entry.isStarred {
                Button {
                    store.setStarred(entry, starred: false)
                } label: {
                    Label("Remove Star", systemImage: "star.slash")
                }
            } else {
                Button {
                    store.setStarred(entry, starred: true)
                } label: {
                    Label("Add Star", systemImage: "star")
                }
            }
            Button(role: .destructive) {
                store.delete(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}
