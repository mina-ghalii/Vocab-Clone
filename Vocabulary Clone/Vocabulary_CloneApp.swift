//
//  Vocabulary_CloneApp.swift
//  Vocabulary Clone
//
//  Created by Mina Ghali on 14/07/2026.
//

import SwiftUI
import SwiftData

@main
struct Vocabulary_CloneApp: App {
    private let modelContainer: ModelContainer

    init() {
        modelContainer = try! ModelContainer(for: WordEntry.self, WordProgress.self)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
