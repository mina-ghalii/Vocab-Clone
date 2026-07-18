import SwiftUI

/// The reading experience's color scheme, chosen during onboarding and persisted.
enum ReadingTheme: String {
    case dark
    case light

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }

    var background: Color {
        switch self {
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .light: return Color(red: 0.937, green: 0.922, blue: 0.878)
        }
    }

    var primaryText: Color {
        switch self {
        case .dark: return .white
        case .light: return .black
        }
    }

    var secondaryText: Color {
        switch self {
        case .dark: return .white.opacity(0.85)
        case .light: return .black.opacity(0.65)
        }
    }

    var iconTint: Color {
        switch self {
        case .dark: return .white
        case .light: return .black
        }
    }

    var chipSelectedBackground: Color { primaryText }
    var chipSelectedText: Color { background }

    var chipUnselectedBackground: Color {
        switch self {
        case .dark: return .white.opacity(0.15)
        case .light: return .black.opacity(0.08)
        }
    }

    var chipUnselectedText: Color { primaryText }
}

private struct ReadingThemeKey: EnvironmentKey {
    static let defaultValue: ReadingTheme = .dark
}

extension EnvironmentValues {
    var readingTheme: ReadingTheme {
        get { self[ReadingThemeKey.self] }
        set { self[ReadingThemeKey.self] = newValue }
    }
}
