//
//  PrivacyTabView.swift
//  CopyPasta
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private struct JSONExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private enum CopyPastaMetadata {
    /// Public source repository for this app (update if the canonical URL changes).
    static let repositoryURL = URL(string: "https://github.com/fishybow/CopyPasta")!
}

struct PrivacyTabView: View {
    @Binding var showPasteboardHelp: Bool
    let store: ClipboardHistoryStore

    @State private var exportDocument: JSONExportDocument?
    @State private var showExportPicker = false
    @State private var exportErrorMessage: String?
    @State private var showExportError = false

    @State private var showImportPicker = false
    @State private var importSuccessCount: Int?
    @State private var showImportSuccess = false
    @State private var importErrorMessage: String?
    @State private var showImportError = false

    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "—"
    }

    private var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "—"
    }

    private var gitCommitURL: URL? {
        guard GitRevision.fullHash != "unknown" else { return nil }
        return CopyPastaMetadata.repositoryURL
            .appendingPathComponent("commit")
            .appendingPathComponent(GitRevision.fullHash)
    }

    private var defaultExportBasename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return "CopyPasta-history-\(formatter.string(from: Date()))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(
                        "CopyPasta does not upload your data anywhere. Clipboard text and your history are stored only on this device."
                    )
                    .font(.body)
                    .foregroundStyle(.primary)
                }

                Section {
                    Button {
                        showPasteboardHelp = true
                    } label: {
                        Label("Clipboard Access Help", systemImage: "questionmark.circle")
                    }
                } footer: {
                    Text(
                        "If iOS asks before reading the clipboard, use this guide to allow paste access so clips can be captured automatically while the app is open."
                    )
                }

                Section {
                    Button {
                        startJSONExport()
                    } label: {
                        Label("Export All Entries to JSON", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import Entries from JSON", systemImage: "square.and.arrow.down")
                    }
                } footer: {
                    Text(
                        "Backup format is UTF-8 JSON (exportVersion 1). Export saves every clip; import adds clips to your history and preserves dates and starred flags. Duplicate text is not merged. Empty text rows are skipped."
                    )
                }

                Section {
                    Link(destination: CopyPastaMetadata.repositoryURL) {
                        Label("Source repository", systemImage: "link")
                    }
                } footer: {
                    Text(
                        "This app is open source and is built directly from that repository. You can read the code and produce the same binary yourself."
                    )
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: appBuild)
                    if let url = gitCommitURL {
                        Link(destination: url) {
                            LabeledContent("Git commit", value: GitRevision.shortHash)
                        }
                    } else {
                        LabeledContent("Git commit", value: GitRevision.shortHash)
                    }
                } footer: {
                    Text(
                        "Git commit is the repository revision used for this build. Tap to open it on GitHub when available."
                    )
                }
            }
            .navigationTitle("Privacy")
            .fileExporter(
                isPresented: $showExportPicker,
                document: exportDocument,
                contentType: .json,
                defaultFilename: defaultExportBasename
            ) { result in
                exportDocument = nil
                if case .failure(let error) = result {
                    exportErrorMessage = error.localizedDescription
                    showExportError = true
                }
            }
            .alert("Could Not Export", isPresented: $showExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportErrorMessage ?? "Unknown error.")
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleJSONImportResult(result)
            }
            .alert("Import Complete", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                if let importSuccessCount {
                    Text(
                        importSuccessCount == 0
                            ? "No clips were added. The file may only contain empty text entries."
                            : "\(importSuccessCount) clip\(importSuccessCount == 1 ? "" : "s") added to your history."
                    )
                }
            }
            .alert("Could Not Import", isPresented: $showImportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "Unknown error.")
            }
        }
    }

    private func startJSONExport() {
        do {
            let data = try store.exportAllEntriesJSON()
            exportDocument = JSONExportDocument(data: data)
            showExportPicker = true
        } catch {
            exportErrorMessage = error.localizedDescription
            showExportError = true
        }
    }

    private func handleJSONImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Could not read the selected file."
                showImportError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let count = try store.importEntriesFromJSON(data)
                importSuccessCount = count
                showImportSuccess = true
            } catch {
                importErrorMessage = error.localizedDescription
                showImportError = true
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showImportError = true
        }
    }
}

#Preview {
    PrivacyTabView(showPasteboardHelp: .constant(false), store: ClipboardHistoryStore())
        .modelContainer(for: ClipboardEntry.self, inMemory: true)
}
