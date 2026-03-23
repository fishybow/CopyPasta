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
    @State private var flashCopiedID: PersistentIdentifier?

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

    private func copyWithFeedback(_ entry: ClipboardEntry) {
        store.copyToPasteboard(entry)
        let haptic = UINotificationFeedbackGenerator()
        haptic.prepare()
        haptic.notificationOccurred(.success)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
            flashCopiedID = entry.persistentModelID
        }
        let id = entry.persistentModelID
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550))
            withAnimation(.easeOut(duration: 0.25)) {
                if flashCopiedID == id {
                    flashCopiedID = nil
                }
            }
        }
    }

    @ViewBuilder
    private func row(for entry: ClipboardEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.text)
                    .font(.body)
                    .lineLimit(4)
                Text(entry.capturedAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if flashCopiedID == entry.persistentModelID {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: flashCopiedID == entry.persistentModelID)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            copyWithFeedback(entry)
        }
        .padding(.vertical, 4)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.accentColor.opacity(flashCopiedID == entry.persistentModelID ? 0.14 : 0))
        )
        .contextMenu {
            Button {
                copyWithFeedback(entry)
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
                copyWithFeedback(entry)
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
