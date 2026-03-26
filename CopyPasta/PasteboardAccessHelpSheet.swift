//
//  PasteboardAccessHelpSheet.swift
//  CopyPasta
//

import SwiftUI
import UIKit

struct PasteboardAccessHelpSheet: View {
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
