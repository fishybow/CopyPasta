//
//  FullContentViews.swift
//  CopyPasta
//

import SwiftData
import SwiftUI
import UIKit

struct FullContentDetail: Identifiable {
    let id = UUID()
    let text: String
    let capturedAt: Date

    init(from entry: ClipboardEntry) {
        text = entry.text
        capturedAt = entry.capturedAt
    }
}

struct FullContentSelectableText: UIViewRepresentable {
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

struct FullContentSheet: View {
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
