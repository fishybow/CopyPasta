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
    var isStarred: Bool

    init(text: String, capturedAt: Date = .now, isStarred: Bool = false) {
        self.text = text
        self.capturedAt = capturedAt
        self.isStarred = isStarred
    }
}
