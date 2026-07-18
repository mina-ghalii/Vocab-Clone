import Foundation

/// Wraps the `WordEntry` shown in the info bottom sheet so it can drive
/// `.sheet(item:)` independent of `WordEntry`'s own identity.
struct WordInfoPresentation: Identifiable {
    let id: String
    let entry: WordEntry

    init(entry: WordEntry) {
        self.id = entry.id
        self.entry = entry
    }
}
