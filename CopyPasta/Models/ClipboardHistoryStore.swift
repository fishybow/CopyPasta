//
//  ClipboardHistoryStore.swift
//  CopyPasta
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

// MARK: - JSON backup (export / import)

private struct ClipboardHistoryExportPayload: Codable {
    let exportVersion: Int
    /// Present in files this app writes; optional when decoding hand-edited JSON.
    let exportedAt: Date?
    let entries: [ClipboardHistoryExportEntry]
}

private struct ClipboardHistoryExportEntry: Codable {
    let text: String
    let capturedAt: Date
    let isStarred: Bool
}

@Observable
@MainActor
final class ClipboardHistoryStore {
    private static let pasteboardFingerprintKey = "CopyPasta.lastPasteboardFingerprint"

    private(set) var entries: [ClipboardEntry] = []
    private(set) var hasMore = true
    private(set) var starredEntries: [ClipboardEntry] = []
    private(set) var hasMoreStarred = true

    private var modelContext: ModelContext?
    private var fetchOffset = 0
    private var fetchStarredOffset = 0
    private let pageSize = 40
    private var isLoadingPage = false
    private var isLoadingStarredPage = false
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

    func loadInitialStarred() {
        starredEntries.removeAll()
        fetchStarredOffset = 0
        hasMoreStarred = true
        loadNextStarredPage()
    }

    func loadNextStarredPage() {
        guard let modelContext, !isLoadingStarredPage, hasMoreStarred else { return }
        isLoadingStarredPage = true
        defer { isLoadingStarredPage = false }

        let starred = #Predicate<ClipboardEntry> { $0.isStarred == true }
        var descriptor = FetchDescriptor<ClipboardEntry>(
            predicate: starred,
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = fetchStarredOffset

        guard let batch = try? modelContext.fetch(descriptor) else { return }
        starredEntries.append(contentsOf: batch)
        fetchStarredOffset += batch.count
        hasMoreStarred = batch.count == pageSize
    }

    func setStarred(_ entry: ClipboardEntry, starred: Bool) {
        guard let modelContext else { return }
        guard entry.isStarred != starred else { return }
        entry.isStarred = starred
        try? modelContext.save()
        loadInitialStarred()
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
        starredEntries.removeAll { $0.persistentModelID == entry.persistentModelID }
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
        loadInitialStarred()
    }

    func copyToPasteboard(_ entry: ClipboardEntry) {
        UIPasteboard.general.string = entry.text
        lastPasteboardText = entry.text
        UserDefaults.standard.set(entry.text, forKey: Self.pasteboardFingerprintKey)
    }

    /// All saved clips, newest first, encoded as JSON for backup or transfer.
    func exportAllEntriesJSON() throws -> Data {
        guard let modelContext else {
            throw ClipboardExportError.storeNotReady
        }
        let descriptor = FetchDescriptor<ClipboardEntry>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        let payload = ClipboardHistoryExportPayload(
            exportVersion: 1,
            exportedAt: Date(),
            entries: all.map {
                ClipboardHistoryExportEntry(text: $0.text, capturedAt: $0.capturedAt, isStarred: $0.isStarred)
            }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    /// Inserts clips from JSON produced by this app (`exportVersion` 1). Skips entries whose text is empty after trimming. Returns how many rows were added.
    func importEntriesFromJSON(_ data: Data) throws -> Int {
        guard let modelContext else {
            throw ClipboardImportError.storeNotReady
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload: ClipboardHistoryExportPayload
        do {
            payload = try decoder.decode(ClipboardHistoryExportPayload.self, from: data)
        } catch {
            throw ClipboardImportError.invalidJSON(error)
        }
        guard payload.exportVersion == 1 else {
            throw ClipboardImportError.unsupportedVersion(payload.exportVersion)
        }
        var inserted = 0
        for item in payload.entries {
            let text = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            let entry = ClipboardEntry(text: text, capturedAt: item.capturedAt, isStarred: item.isStarred)
            modelContext.insert(entry)
            inserted += 1
        }
        try modelContext.save()
        loadInitial()
        loadInitialStarred()
        return inserted
    }
}

enum ClipboardExportError: LocalizedError {
    case storeNotReady

    var errorDescription: String? {
        switch self {
        case .storeNotReady:
            "Clipboard history is not available yet. Try again in a moment."
        }
    }
}

enum ClipboardImportError: LocalizedError {
    case storeNotReady
    case invalidJSON(Error)
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .storeNotReady:
            "Clipboard history is not available yet. Try again in a moment."
        case .invalidJSON:
            "The file is not valid CopyPasta backup JSON."
        case .unsupportedVersion(let v):
            "This backup uses export version \(v), which this version of the app does not support."
        }
    }
}

#if DEBUG
extension ClipboardHistoryStore {
    /// Inserts five realistic clips with staggered timestamps (newest first after reload). Debug builds only.
    func seedDebugSampleEntries() {
        guard let modelContext else { return }

        let base = Date.now
        let samples: [(text: String, secondsAgo: TimeInterval, starred: Bool)] = [
            (
                """
                Marina — looping you in on the vendor MSA redlines. Latest PDF is in Drive under Legal/Vendors/MSA-draft-v4.pdf. Legal wants sign-off by Friday COB if we want Feb 1 effective date.
                """,
                0,
                true
            ),
            (
                "https://maps.apple.com/?address=1+Infinite+Loop,+Cupertino,+CA+95014",
                12 * 60,
                false
            ),
            (
                """
                func reconcile(_ items: [Item]) async throws -> Summary {
                    try await coordinator.flushPending()
                    return Summary(count: items.count, updatedAt: .now)
                }
                """,
                47 * 60,
                true
            ),
            (
                "Order #8F29-LL · 2× USB-C braided 2m, 1× 140W GaN adapter · Ship to: 428 Oak St, Apt 3B, Oakland CA · Est. Thu by 8pm",
                3 * 3_600,
                false
            ),
            (
                "All-hands moved to 10:30am PT tomorrow — same Zoom as last week (check the updated calendar invite). Q4 roadmap slides due EOD today if you’re presenting.",
                26 * 3_600,
                false
            ),
        ]

        for sample in samples {
            let capturedAt = base.addingTimeInterval(-sample.secondsAgo)
            let entry = ClipboardEntry(text: sample.text.trimmingCharacters(in: .whitespacesAndNewlines), capturedAt: capturedAt, isStarred: sample.starred)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        loadInitial()
        loadInitialStarred()
    }
}
#endif
