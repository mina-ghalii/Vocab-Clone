import Foundation
import Observation

/// Drives the reel screen: windowed loading of `WordEntry` cards around the
/// user's resume position, seen-tracking as cards scroll past, and like/save
/// toggling. Depends only on protocols, so it can be unit-tested with fakes.
@Observable
final class ReelViewModel {
    private(set) var loadedEntries: [WordEntry] = []
    private(set) var progressByEntryId: [String: WordProgress] = [:]
    private(set) var totalCount: Int = 0
    var selectedAccent: AudioAccent
    var pendingShare: ShareableImage?

    private let repository: WordQuerying & WordStateMutating
    private let audioPlayer: AudioPlayerProtocol
    private let shareImageGenerator: ShareImageGenerating
    private let pageSize: Int
    private let prefetchThreshold: Int
    private var isLoadingMore = false

    init(
        repository: WordQuerying & WordStateMutating,
        audioPlayer: AudioPlayerProtocol,
        shareImageGenerator: ShareImageGenerating,
        preferredAccent: AudioAccent = .uk,
        pageSize: Int = 20,
        prefetchThreshold: Int = 5
    ) {
        self.repository = repository
        self.audioPlayer = audioPlayer
        self.shareImageGenerator = shareImageGenerator
        self.selectedAccent = preferredAccent
        self.pageSize = pageSize
        self.prefetchThreshold = prefetchThreshold
    }

    func start() async {
        guard loadedEntries.isEmpty else { return }
        do {
            totalCount = try await repository.totalCount()
            let resumeIndex = try await repository.resumeIndex()
            loadedEntries = try await repository.words(from: resumeIndex, limit: pageSize)
        } catch {
            loadedEntries = []
        }
    }

    func cardAppeared(_ entry: WordEntry, at localIndex: Int) async {
        audioPlayer.stop()
        await loadProgressIfNeeded(for: entry)
        try? await repository.markSeen(entryId: entry.id)
        try? await repository.setResumeIndex(entry.sortIndex)
        await loadMoreIfNeeded(localIndex: localIndex)
    }

    func selectAccent(_ accent: AudioAccent) {
        selectedAccent = accent
    }

    func toggleLike(_ entry: WordEntry) async {
        _ = try? await repository.toggleLiked(entryId: entry.id)
        await loadProgressIfNeeded(for: entry, forceReload: true)
    }

    func toggleSave(_ entry: WordEntry) async {
        _ = try? await repository.toggleSaved(entryId: entry.id)
        await loadProgressIfNeeded(for: entry, forceReload: true)
    }

    func playCurrentAudio(for entry: WordEntry) {
        let fileName = selectedAccent == .uk ? entry.ukAudioFile : entry.usAudioFile
        try? audioPlayer.play(audioFileName: fileName)
    }

    func shareCurrentCard(_ entry: WordEntry) {
        guard let image = shareImageGenerator.image(for: entry) else { return }
        pendingShare = ShareableImage(image: image)
    }

    /// Stubbed per product request — detail sheet to be attached later.
    func infoTapped(for entry: WordEntry) {}

    private func loadProgressIfNeeded(for entry: WordEntry, forceReload: Bool = false) async {
        guard forceReload || progressByEntryId[entry.id] == nil else { return }
        if let progress = try? await repository.progress(for: entry.id) {
            progressByEntryId[entry.id] = progress
        }
    }

    private func loadMoreIfNeeded(localIndex: Int) async {
        guard !isLoadingMore else { return }
        guard localIndex >= loadedEntries.count - prefetchThreshold else { return }
        guard let last = loadedEntries.last, last.sortIndex + 1 < totalCount else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        if let more = try? await repository.words(from: last.sortIndex + 1, limit: pageSize) {
            loadedEntries.append(contentsOf: more)
        }
    }
}
