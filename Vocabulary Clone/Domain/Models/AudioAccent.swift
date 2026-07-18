/// Which pronunciation recording to play for a word.
enum AudioAccent: String, CaseIterable, Identifiable {
    case uk
    case us

    var id: String { rawValue }

    var title: String {
        switch self {
        case .uk: return "British"
        case .us: return "American"
        }
    }
}
