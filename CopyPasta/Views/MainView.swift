//
//  MainView.swift
//  CopyPasta
//

import SwiftData
import SwiftUI
import UIKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = ClipboardHistoryStore()
    @State private var flashCopiedID: PersistentIdentifier?
    @State private var showPasteboardHelp = false
    @State private var showClearAllConfirmation = false
    @State private var fullContentDetail: FullContentDetail?
    @State private var starredTabPrimed = false

    var body: some View {
        TabView {
            AllEntriesTabView(
                store: store,
                flashCopiedID: flashCopiedID,
                fullContentDetail: $fullContentDetail,
                showPasteboardHelp: $showPasteboardHelp,
                showClearAllConfirmation: $showClearAllConfirmation,
                onCopy: copyWithFeedback
            )
            .tabItem {
                Label("All", systemImage: "list.bullet")
            }

            StarredEntriesTabView(
                store: store,
                flashCopiedID: flashCopiedID,
                fullContentDetail: $fullContentDetail,
                showPasteboardHelp: $showPasteboardHelp,
                showClearAllConfirmation: $showClearAllConfirmation,
                starredTabPrimed: $starredTabPrimed,
                onCopy: copyWithFeedback
            )
            .tabItem {
                Label("Starred", systemImage: "star.fill")
            }

            PrivacyTabView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised.fill")
                }
        }
        .sheet(isPresented: $showPasteboardHelp) {
            PasteboardAccessHelpSheet()
        }
        .sheet(item: $fullContentDetail) { detail in
            FullContentSheet(detail: detail)
        }
        .confirmationDialog(
            "Clear All Entries?",
            isPresented: $showClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                store.clearAllEntries()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every saved clip from this device. It cannot be undone.")
        }
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
}

#Preview {
    MainView()
        .modelContainer(for: ClipboardEntry.self, inMemory: true)
}
