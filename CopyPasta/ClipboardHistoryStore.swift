//
//  ClipboardHistoryStore.swift
//  CopyPasta
//

import SwiftData
import SwiftUI
import UIKit

@Observable
@MainActor
final class ClipboardHistoryStore {
    private static let pasteboardFingerprintKey = "CopyPasta.lastPasteboardFingerprint"

    private(set) var entries: [ClipboardEntry] = []
    private(set) var hasMore = true

    private var modelContext: ModelContext?
    private var fetchOffset = 0
    private let pageSize = 40
    private var isLoadingPage = false
    private var lastPasteboardText: String?

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
        if lastPasteboardText == nil {
            lastPasteboardText = UserDefaults.standard.string(forKey: Self.pasteboardFingerprintKey)
        }
    }

    func loadInitial() {
        entries.removeAll()
        fetchOffset = 0
        hasMore = true
        loadNextPage()
    }

    func loadNextPage() {
        guard let modelContext, !isLoadingPage, hasMore else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }

        var descriptor = FetchDescriptor<ClipboardEntry>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = fetchOffset

        guard let batch = try? modelContext.fetch(descriptor) else { return }
        entries.append(contentsOf: batch)
        fetchOffset += batch.count
        hasMore = batch.count == pageSize
    }

    /// Persists pasteboard text when it changes; then reloads the first page so newest items stay correct.
    func capturePasteboardIfChanged() {
        guard let modelContext else { return }
        guard let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else { return }
        guard text != lastPasteboardText else { return }

        lastPasteboardText = text
        UserDefaults.standard.set(text, forKey: Self.pasteboardFingerprintKey)
        let entry = ClipboardEntry(text: text, capturedAt: .now)
        modelContext.insert(entry)
        try? modelContext.save()

        loadInitial()
    }

    func delete(_ entry: ClipboardEntry) {
        guard let modelContext else { return }
        modelContext.delete(entry)
        entries.removeAll { $0.persistentModelID == entry.persistentModelID }
        try? modelContext.save()
    }

    func clearAllEntries() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<ClipboardEntry>()
        guard let all = try? modelContext.fetch(descriptor) else { return }
        for entry in all {
            modelContext.delete(entry)
        }
        try? modelContext.save()
        loadInitial()
    }

    func copyToPasteboard(_ entry: ClipboardEntry) {
        UIPasteboard.general.string = entry.text
        lastPasteboardText = entry.text
        UserDefaults.standard.set(entry.text, forKey: Self.pasteboardFingerprintKey)
    }
}
