# CopyPasta

An iOS app that records plain text from your pasteboard while the app is open and keeps a local history in SwiftData.

## Why this is open source

Apps that read the clipboard sit in a sensitive position. The pasteboard often holds passwords, links, messages, and other private material. Granting any closed-source app ongoing access to that surface is a poor trade: you are expected to trust behavior you cannot verify.

CopyPasta is open source so you can **read every line of code**, **build the binary yourself**, and run it with **full confidence** that it does what it claims—capture text you copy while the app is active, store it only on your device, and not exfiltrate or misuse it. If that level of transparency still feels like too much permission, the source is there to judge for yourself or to fork and narrow further.

## What it does

See [SPEC.md](SPEC.md) for behavior, data model, and UI details.

## Requirements

- Xcode (project targets recent iOS as set in the Xcode project)
- Apple Developer account for running on a physical device, if desired

## License

[MIT License](LICENSE)
