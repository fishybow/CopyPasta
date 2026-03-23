# CopyPasta — Product specification

## Purpose

CopyPasta is an iOS app that records text from the system pasteboard while the app is open, persists each capture in SwiftData, and presents the history in a simple list.

## Platform and stack

- **Platform:** iOS (SwiftUI).
- **Persistence:** SwiftData.
- **UI:** `List` only (no custom collection views).

## Pasteboard behavior

- While the app is **foreground / active**, the app observes pasteboard changes and periodically reconciles when returning to the foreground.
- When readable **plain text** is available and it **differs from the last captured value** (to avoid duplicate rows from repeated notifications), the app inserts a new record with:
  - the string contents, and
  - a **capture timestamp** (when the capture occurred).
- Empty strings are not stored. Non-text–only pasteboard content (e.g. image-only) is out of scope; only `String` payloads are persisted.
- **Deduplication:** identical pasteboard text is not inserted again until the user copies something new (in-memory fingerprint, persisted across launches so reopening the app does not recreate a row for the same clipboard string).

## Data model

- Each stored item is immutable after insert: **no in-app editing or reordering**.
- Fields: `text` (String), `capturedAt` (Date).
- Sort order for display: **newest first** (reverse chronological by `capturedAt`).

## List and pagination

- All entries are shown in a **single-column `List`**, newest at the top.
- **Paged lazy loading:** the list loads an initial page from SwiftData; when the user scrolls near the end of the currently loaded rows, the next page is fetched (fetch limit + offset). Loading is sequential (no speculative multi-page jumps required).

## Row actions

Per row, the user can:

- **Delete** — removes the row from SwiftData and from the UI.
- **Copy** — writes that row’s `text` to the general pasteboard.

There is **no reorder** and **no update** of existing rows.

## Non-goals (this version)

- Background pasteboard monitoring when the app is not active.
- Rich paste (HTML, attributed strings, files) beyond plain text.
- Search, tags, or sync.
