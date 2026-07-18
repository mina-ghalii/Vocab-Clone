import SwiftUI

/// Static, self-contained layout used only for the exported share image —
/// deliberately separate from `WordCardView`, which depends on `ReelViewModel`
/// and includes interactive chrome (action rail, live accent toggle) that has
/// no place in a shared image.
struct ShareableWordCardView: View {
    let entry: WordEntry

    private var primarySense: Sense? { entry.senses.first }

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)

            VStack(spacing: 28) {
                Text(entry.word)
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if let primarySense {
                    Text(primarySense.phonBr)
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.75))
                }

                VStack(spacing: 16) {
                    ForEach(entry.senses, id: \.self) { sense in
                        Text("(\(PartOfSpeechAbbreviation.abbreviate(sense.partOfSpeech))) \(sense.definition)")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 56)
            }
            .padding(48)
        }
        .frame(width: 1080, height: 1080)
    }
}
