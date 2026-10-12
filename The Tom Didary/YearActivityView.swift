import SwiftUI

/// Vykreslí celý aktuální rok jako dva pruhy sloupců týdnů. Výpočet dnů
/// i jejich stavů zůstává v DiaryStatistics; zde se řeší jen vzhled a přístupnost.
struct YearActivityView: View {
    let statistics: DiaryStatistics
    private let spacing: CGFloat = 2

    var body: some View {
        let weeks = statistics.weeks
        let split = (weeks.count + 1) / 2
        VStack(spacing: 12) {
            // Dva pruhy umožní ukázat celý rok na šířku iPhonu bez vodorovného posunu.
            GeometryReader { geometry in
                let cell = max(3, (geometry.size.width - CGFloat(split - 1) * spacing) / CGFloat(max(split, 1)))
                VStack(alignment: .leading, spacing: 12) {
                    half(Array(weeks.prefix(split)), cell: cell)
                    half(Array(weeks.dropFirst(split)), cell: cell)
                }
            }
            .frame(height: 2 * 7 * 10 + 2 * 6 * spacing + 12)
            HStack(spacing: 12) {
                legend("Zapsáno", color: .green)
                legend("Nevyplněno", color: .yellow)
                legend("Budoucí", color: .secondary.opacity(0.18))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text("přehled roku \(String(statistics.year))")
                .font(.caption).foregroundStyle(.secondary)
                .accessibilityIdentifier("activityYearCaption")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Roční přehled")
    }

    /// Každý sloupec je týden od pondělí do neděle. Prázdná krajní místa jsou neviditelná.
    /// Popisky obsahují datum i stav, takže barva není jediný zdroj informace.
    private func half(_ weeks: [[DiaryStatistics.Day?]], cell: CGFloat) -> some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(weeks.indices, id: \.self) { week in
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { weekday in
                        if let day = weeks[week][weekday] {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color(for: day.status))
                                .overlay {
                                    if day.date == statistics.today {
                                        RoundedRectangle(cornerRadius: 2).stroke(.primary.opacity(0.65), lineWidth: 1)
                                    }
                                }
                                .frame(width: cell, height: 10)
                                .accessibilityElement()
                                .accessibilityLabel(day.date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "cs_CZ"))))
                                .accessibilityValue(description(for: day.status))
                                .accessibilityIdentifier("activity-\(DiaryDate.string(day.date))")
                        } else {
                            Color.clear.frame(width: cell, height: 10).accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }

    private func legend(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 7, height: 7)
            Text(label)
        }
    }

    private func color(for status: DiaryStatistics.DayStatus) -> Color {
        switch status {
        case .answered: .green
        case .missed: .yellow
        case .pending: .yellow.opacity(0.5)
        case .future: .secondary.opacity(0.16)
        }
    }

    private func description(for status: DiaryStatistics.DayStatus) -> String {
        switch status {
        case .answered: "Zapsáno"
        case .missed: "Vynecháno"
        case .pending: "Dnes, zatím nevyplněno"
        case .future: "Budoucí den"
        }
    }
}
