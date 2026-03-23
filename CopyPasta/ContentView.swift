//
//  ContentView.swift
//  CopyPasta
//

import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = ClipboardHistoryStore()

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.entries) { entry in
                    row(for: entry)
                        .onAppear {
                            if entry.persistentModelID == store.entries.last?.persistentModelID {
                                store.loadNextPage()
                            }
                        }
                }
            }
            .navigationTitle("CopyPasta")
            .onAppear {
                store.attach(modelContext: modelContext)
                if store.entries.isEmpty {
                    store.loadInitial()
                }
                store.capturePasteboardIfChanged()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    store.capturePasteboardIfChanged()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
                store.capturePasteboardIfChanged()
            }
        }
    }

    @ViewBuilder
    private func row(for entry: ClipboardEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.text)
                .font(.body)
                .lineLimit(4)
            Text(entry.capturedAt, format: .dateTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                store.copyToPasteboard(entry)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
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
                store.copyToPasteboard(entry)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .tint(.blue)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ClipboardEntry.self, inMemory: true)
}
