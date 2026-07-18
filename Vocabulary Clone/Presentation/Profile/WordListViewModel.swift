import Foundation
import Observation

/// Which per-user word list a `WordListView` is displaying.
enum WordListKind: String, Identifiable {
    case history
    case favorites
    case savedWords

    var id: String { rawValue }

    var title: String {
        switch self {
        case .history: return "History"
        case .favorites: return "Favorites"
        case .savedWords: return "Your words"
        }
    }

    var emptyMessage: String {
        switch self {
        case .history: return "Words you view will show up here."
        case .favorites: return "Words you like will show up here."
        case .savedWords: return "Words you save will show up here."
        }
    }
}

/// Drives a single word-list screen (History, Favorites, or Your words):
/// loads the relevant `WordHistoryItem`s and forwards like/save/play/share
/// actions to the shared repository/services.
@Observable
final class WordListViewModel {
    let kind: WordListKind
    private(set) var items: [WordHistoryItem] = []
    var selectedAccent: AudioAccent
    var pendingShare: ShareableImage?

    private let repository: WordHistoryQuerying & WordStateMutating
    private let audioPlayer: AudioPlayerProtocol
    private let shareImageGenerator: ShareImageGenerating

    nonisolated deinit {}

    init(
        kind: WordListKind,
        repository: WordHistoryQuerying & WordStateMutating,
        audioPlayer: AudioPlayerProtocol,
        shareImageGenerator: ShareImageGenerating,
        preferredAccent: AudioAccent
    ) {
        self.kind = kind
        self.repository = repository
        self.audioPlayer = audioPlayer
        self.shareImageGenerator = shareImageGenerator
        self.selectedAccent = preferredAccent
    }

    func load() async {
        do {
            switch kind {
            case .history: items = try await repository.seenEntries()
            case .favorites: items = try await repository.likedEntries()
            case .savedWords: items = try await repository.savedEntries()
            }
        } catch {
            items = []
        }
    }

    func toggleLike(_ item: WordHistoryItem) async {
        _ = try? await repository.toggleLiked(entryId: item.entry.id)
        await load()
    }

    func toggleSave(_ item: WordHistoryItem) async {
        _ = try? await repository.toggleSaved(entryId: item.entry.id)
        await load()
    }

    func playAudio(_ entry: WordEntry) {
        audioPlayer.stop()
        let fileName = selectedAccent == .uk ? entry.ukAudioFile : entry.usAudioFile
        try? audioPlayer.play(audioFileName: fileName)
    }

    func shareTapped(_ entry: WordEntry) {
        guard let image = shareImageGenerator.image(for: entry) else { return }
        pendingShare = ShareableImage(image: image)
    }
}
