import Foundation

/// Maps onboarding topic answers straight onto `WordTags.topics` keys — a plain
/// lookup, not something sent to an LLM. Topic preference is a filter/ordering
/// concern (`PersonalizedWordOrderer`), not something that needs inference: the
/// user already told us exactly which topics they want, in their own words.
enum OnboardingTopicMapper {
    private static let tagKeyByOption: [String: String] = [
        "Society": "society",
        "Emotions": "emotions",
        "Words in foreign languages": "foreign_loanwords",
        "Human body": "human_body",
        "Business": "business",
        "Nature": "nature",
        "Science & technology": "science_technology",
        "Arts & entertainment": "arts_entertainment",
        "Travel": "travel_transport",
    ]

    static func tagKeys(for profile: OnboardingProfile) -> Set<String> {
        var keys = Set(profile.topics.compactMap { tagKeyByOption[$0] })
        if profile.weakestAreas.contains("At work") {
            keys.insert("business")
        }
        if profile.weakestAreas.contains("In social conversations") {
            keys.insert("emotions")
            keys.insert("society")
        }
        return keys
    }
}
