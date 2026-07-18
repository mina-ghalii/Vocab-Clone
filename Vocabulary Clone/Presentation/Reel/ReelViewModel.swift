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
    var pendingInfo: WordInfoPresentation?
    private(set) var streakSummary: StreakSummary?
    private(set) var isStreakPanelVisible = false
    private(set) var pronunciationState: PronunciationCheckState = .idle

    let repository: WordQuerying & WordStateMutating & WordHistoryQuerying
    let audioPlayer: AudioPlayerProtocol
    let shareImageGenerator: ShareImageGenerating
    private let streakTracking: StreakTracking
    private let speechRecognizer: SpeechRecognizing
    private let pageSize: Int
    private let prefetchThreshold: Int
    private var isLoadingMore = false
    private var pronunciationResetTask: Task<Void, Never>?

    nonisolated deinit {}

    init(
        repository: WordQuerying & WordStateMutating & WordHistoryQuerying,
        audioPlayer: AudioPlayerProtocol,
        shareImageGenerator: ShareImageGenerating,
        streakTracking: StreakTracking = UserDefaultsStreakTrackingService(),
        speechRecognizer: SpeechRecognizing = AppleSpeechRecognitionService(),
        preferredAccent: AudioAccent = .uk,
        pageSize: Int = 20,
        prefetchThreshold: Int = 5
    ) {
        self.repository = repository
        self.audioPlayer = audioPlayer
        self.shareImageGenerator = shareImageGenerator
        self.streakTracking = streakTracking
        self.speechRecognizer = speechRecognizer
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
        resetPronunciationCheck()
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

    /// Called when the user presses down on the mic button (WhatsApp-style
    /// press-and-hold). Requests permission on first use, then starts
    /// capturing audio for the duration of the press.
    func beginPronunciationCheck(for entry: WordEntry) async {
        guard pronunciationState == .idle else { return }
        pronunciationResetTask?.cancel()
        audioPlayer.stop()
        // Placeholder state while authorization is (usually instantly)
        // confirmed — also blocks a second press-down from racing in.
        pronunciationState = .processing

        guard await speechRecognizer.requestAuthorization() else {
            pronunciationState = .incorrect(transcript: "")
            scheduleReturnToIdle()
            return
        }
        do {
            try speechRecognizer.startRecording()
            pronunciationState = .recording
        } catch {
            pronunciationState = .incorrect(transcript: "")
            scheduleReturnToIdle()
        }
    }

    /// Called when the user releases the mic button. Stops capturing and
    /// validates the transcript against the current word.
    func endPronunciationCheck(for entry: WordEntry) async {
        guard pronunciationState == .recording else { return }
        pronunciationState = .processing

        let transcript = (try? await speechRecognizer.stopRecording()) ?? ""
        pronunciationState = PronunciationMatcher.isMatch(transcript: transcript, target: entry.word)
            ? .correct
            : .incorrect(transcript: transcript)
        scheduleReturnToIdle()
    }

    private func resetPronunciationCheck() {
        pronunciationResetTask?.cancel()
        pronunciationState = .idle
    }

    private func scheduleReturnToIdle() {
        pronunciationResetTask?.cancel()
        pronunciationResetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            pronunciationState = .idle
        }
    }

    func shareCurrentCard(_ entry: WordEntry) {
        guard let image = shareImageGenerator.image(for: entry) else { return }
        pendingShare = ShareableImage(image: image)
    }

    func infoTapped(for entry: WordEntry) {
        pendingInfo = WordInfoPresentation(entry: entry)
    }

    /// Shows the streak panel for 5 seconds on the first launch of a calendar
    /// day, then auto-dismisses it. Refreshes the streak count either way.
    func presentStreakPanelIfNeeded() async {
        let isFirstOpenToday = streakTracking.recordAppOpened()
        streakSummary = streakTracking.currentSummary()
        guard isFirstOpenToday else { return }

        isStreakPanelVisible = true
        try? await Task.sleep(for: .seconds(5))
        isStreakPanelVisible = false
    }

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
