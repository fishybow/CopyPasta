//
//  PrivacyTabView.swift
//  CopyPasta
//

import SwiftUI

private enum CopyPastaMetadata {
    /// Public source repository for this app (update if the canonical URL changes).
    static let repositoryURL = URL(string: "https://github.com/fishybow/CopyPasta")!
}

struct PrivacyTabView: View {
    @Binding var showPasteboardHelp: Bool

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
        }
    }
}

#Preview {
    PrivacyTabView(showPasteboardHelp: .constant(false))
}
