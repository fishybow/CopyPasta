//
//  ClipboardEntry.swift
//  CopyPasta
//

import Foundation
import SwiftData

@Model
final class ClipboardEntry {
    var text: String
    var capturedAt: Date

    init(text: String, capturedAt: Date = .now) {
        self.text = text
        self.capturedAt = capturedAt
    }
}
