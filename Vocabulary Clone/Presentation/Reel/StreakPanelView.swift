import SwiftUI

/// Once-daily banner: current streak flame + a 7-day rolling strip showing
/// which days the app was opened. `ReelViewModel` shows this briefly on the
/// first launch of a calendar day, then auto-dismisses it.
struct StreakPanelView: View {
    let summary: StreakSummary

    var body: some View {
        HStack(spacing: 16) {
            flame

            HStack(spacing: 12) {
                ForEach(summary.days) { day in
                    VStack(spacing: 8) {
                        Text(day.weekdaySymbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(day.isToday ? .white : .white.opacity(0.5))
                        badge(for: day.status)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var flame: some View {
        ZStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 46))
                .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
            Text("\(summary.currentStreakCount)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: 7)
        }
        .frame(width: 60, height: 60)
    }

    @ViewBuilder
    private func badge(for status: StreakDayStatus) -> some View {
        switch status {
        case .completed:
            ZStack {
                Circle().fill(Color.teal.opacity(0.4))
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)
        case .missed, .upcoming:
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 32, height: 32)
        }
    }
}
