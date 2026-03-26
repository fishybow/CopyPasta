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
    private var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "—"
    }

    private var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "—"
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
                }
            }
            .navigationTitle("Privacy")
        }
    }
}

#Preview {
    PrivacyTabView()
}
