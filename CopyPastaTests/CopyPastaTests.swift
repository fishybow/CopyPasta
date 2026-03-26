//
//  CopyPastaTests.swift
//  CopyPastaTests
//

import Foundation
import SwiftData
import Testing
@testable import CopyPasta

// Mirrors `ClipboardHistoryExportPayload` / entry shape for decoding in tests (app types are file-private).
private struct TestBackupPayload: Codable {
    let exportVersion: Int
    let exportedAt: Date?
    let entries: [TestBackupEntry]
}

private struct TestBackupEntry: Codable {
    let text: String
    let capturedAt: Date
    let isStarred: Bool
}

@Suite("ClipboardHistoryStore JSON backup")
@MainActor
struct ClipboardHistoryBackupTests {

    private func makeStore() throws -> (ClipboardHistoryStore, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ClipboardEntry.self, configurations: config)
        let context = ModelContext(container)
        let store = ClipboardHistoryStore()
        store.attach(modelContext: context)
        store.loadInitial()
        return (store, context)
    }

    @Test func exportThrowsWhenStoreNotAttached() throws {
        let store = ClipboardHistoryStore()
        #expect(throws: ClipboardExportError.self) {
            try store.exportAllEntriesJSON()
        }
    }

    @Test func importThrowsWhenStoreNotAttached() throws {
        let store = ClipboardHistoryStore()
        let data = Data("{}".utf8)
        #expect(throws: ClipboardImportError.self) {
            try store.importEntriesFromJSON(data)
        }
    }

    @Test func exportEmptyProducesValidPayload() throws {
        let (store, _) = try makeStore()
        let data = try store.exportAllEntriesJSON()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestBackupPayload.self, from: data)
        #expect(decoded.exportVersion == 1)
        #expect(decoded.exportedAt != nil)
        #expect(decoded.entries.isEmpty)
    }

    @Test func exportOrdersNewestFirst() throws {
        let (store, context) = try makeStore()
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        context.insert(ClipboardEntry(text: "older", capturedAt: older, isStarred: false))
        context.insert(ClipboardEntry(text: "newer", capturedAt: newer, isStarred: true))
        try context.save()
        store.loadInitial()

        let data = try store.exportAllEntriesJSON()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestBackupPayload.self, from: data)
        #expect(decoded.entries.count == 2)
        #expect(decoded.entries[0].text == "newer")
        #expect(decoded.entries[0].isStarred == true)
        #expect(decoded.entries[1].text == "older")
    }

    @Test func importInsertsEntriesAndSkipsEmptyText() throws {
        let (store, context) = try makeStore()
        let json = """
        {"exportVersion":1,"exportedAt":"2020-01-01T00:00:00Z","entries":[
            {"text":"  ","capturedAt":"2020-01-02T00:00:00Z","isStarred":false},
            {"text":"hello","capturedAt":"2020-01-03T00:00:00Z","isStarred":true}
        ]}
        """
        let data = Data(json.utf8)
        let inserted = try store.importEntriesFromJSON(data)
        #expect(inserted == 1)

        let descriptor = FetchDescriptor<ClipboardEntry>(
            sortBy: [SortDescriptor(\.capturedAt, order: .forward)]
        )
        let all = try context.fetch(descriptor)
        #expect(all.count == 1)
        #expect(all[0].text == "hello")
        #expect(all[0].isStarred == true)
    }

    @Test func importRejectsUnsupportedExportVersion() throws {
        let (store, _) = try makeStore()
        let json = #"{"exportVersion":99,"entries":[]}"#
        #expect(throws: ClipboardImportError.self) {
            try store.importEntriesFromJSON(Data(json.utf8))
        }
    }

    @Test func importRejectsInvalidJSON() throws {
        let (store, _) = try makeStore()
        let data = Data("not json".utf8)
        #expect(throws: ClipboardImportError.self) {
            try store.importEntriesFromJSON(data)
        }
    }

    @Test func exportThenImportRoundTrip() throws {
        let (store, context) = try makeStore()
        let d1 = Date(timeIntervalSince1970: 5_000)
        let d2 = Date(timeIntervalSince1970: 6_000)
        context.insert(ClipboardEntry(text: "alpha", capturedAt: d1, isStarred: true))
        context.insert(ClipboardEntry(text: "beta", capturedAt: d2, isStarred: false))
        try context.save()
        store.loadInitial()

        let exported = try store.exportAllEntriesJSON()
        store.clearAllEntries()
        #expect(store.entries.isEmpty)

        let inserted = try store.importEntriesFromJSON(exported)
        #expect(inserted == 2)

        let descriptor = FetchDescriptor<ClipboardEntry>(
            sortBy: [SortDescriptor(\.capturedAt, order: .forward)]
        )
        let all = try context.fetch(descriptor)
        #expect(all.count == 2)
        let sorted = all.sorted { $0.capturedAt < $1.capturedAt }
        #expect(sorted[0].text == "alpha" && sorted[0].isStarred == true)
        #expect(sorted[1].text == "beta" && sorted[1].isStarred == false)
    }
}
