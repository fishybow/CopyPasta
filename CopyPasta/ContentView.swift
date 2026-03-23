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
    @State private var showPasteboardHelp = false
    @State private var showClearAllConfirmation = false
    @State private var fullContentDetail: FullContentDetail?
    @State private var starredTabPrimed = false

    var body: some View {
        TabView {
            NavigationStack {
                entriesList(
                    entries: store.entries,
                    loadNextPage: { store.loadNextPage() }
                )
                .navigationTitle("CopyPasta")
                .copyPastaNavigationToolbar(
                    showPasteboardHelp: $showPasteboardHelp,
                    showClearAllConfirmation: $showClearAllConfirmation,
                    onReadClipboard: { store.capturePasteboardIfChanged() }
                )
            }
            .tabItem {
                Label("All", systemImage: "list.bullet")
            }

            NavigationStack {
                entriesList(
                    entries: store.starredEntries,
                    loadNextPage: { store.loadNextStarredPage() }
                )
                .navigationTitle("Starred")
                .copyPastaNavigationToolbar(
                    showPasteboardHelp: $showPasteboardHelp,
                    showClearAllConfirmation: $showClearAllConfirmation,
                    onReadClipboard: { store.capturePasteboardIfChanged() }
                )
                .onAppear {
                    if !starredTabPrimed {
                        starredTabPrimed = true
                        store.loadInitialStarred()
                    }
                }
            }
            .tabItem {
                Label("Starred", systemImage: "star.fill")
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

    @ViewBuilder
    private func entriesList(
        entries: [ClipboardEntry],
        loadNextPage: @escaping () -> Void
    ) -> some View {
        List {
            ForEach(entries) { entry in
                ClipboardEntryRow(
                    entry: entry,
                    store: store,
                    isCopiedFlash: flashCopiedID == entry.persistentModelID,
                    onCopy: { copyWithFeedback(entry) },
                    onViewFullContent: { fullContentDetail = FullContentDetail(from: entry) }
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

private extension View {
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

private struct FullContentDetail: Identifiable {
    let id = UUID()
    let text: String
    let capturedAt: Date

    init(from entry: ClipboardEntry) {
        text = entry.text
        capturedAt = entry.capturedAt
    }
}

private struct FullContentSelectableText: UIViewRepresentable {
    let text: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.textColor = UIColor.label
        view.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = true
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}

private struct FullContentSheet: View {
    let detail: FullContentDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FullContentSelectableText(text: detail.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Full Content")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Text(detail.capturedAt, format: .dateTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.bar)
                }
        }
    }
}

private struct PasteboardAccessHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Allow Clipboard Access")
                        .font(.title2.weight(.semibold))

                    Text(
                        "iOS can prompt before CopyPasta reads the clipboard. To record copies automatically while the app is open, allow paste access in Settings."
                    )
                    .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        instructionRow(number: 1, text: "Open Settings.")
                        instructionRow(number: 2, text: "Scroll to CopyPasta and tap it.")
                        instructionRow(number: 3, text: "Tap Paste from Other Apps.")
                        instructionRow(
                            number: 4,
                            text: "Choose Allow so the system does not ask every time."
                        )
                    }

                    Button {
                        openAppSettings()
                    } label: {
                        Label("Open CopyPasta in Settings", systemImage: "gearshape")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)

                    Text(
                        "This opens this app’s Settings page. If you do not see “Paste from Other Apps,” update to a recent iOS version."
                    )
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.body)
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ClipboardEntry.self, inMemory: true)
}
