//
//  FullCalendarView.swift
//  Learning Journey
//
//  Created by Teif May on 30/04/1447 AH.
//

import SwiftUI

struct FullCalendarView: View {
    let learnedDates: Set<Date>
    let frozenDates: Set<Date>
    let accent: Color
    let frozen: Color

    @State private var monthAnchor: Date = Date()

    private var monthTitle: String {
        monthAnchor.formatted(.dateTime.year().month(.wide))
    }

    private var daysInMonth: [Date] {
        let cal = Calendar.current
        guard
            let range = cal.range(of: .day, in: .month, for: monthAnchor),
            let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor))
        else { return [] }

        // Leading blanks for weekday alignment
        let firstWeekday = cal.component(.weekday, from: startOfMonth) // 1..7
        let leadingEmpty = (firstWeekday - cal.firstWeekday + 7) % 7

        var days: [Date] = []
        // prepend empty slots with nil-equivalents as dates shifted negative
        for i in 0..<leadingEmpty {
            if let d = cal.date(byAdding: .day, value: i - leadingEmpty, to: startOfMonth) {
                days.append(d) // will be from previous month; we’ll render as empty
            }
        }
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(d)
            }
        }
        return days
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button { changeMonth(by: -1) } label: {
                        Image(systemName: "chevron.left").foregroundColor(accent)
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button { changeMonth(by: 1) } label: {
                        Image(systemName: "chevron.right").foregroundColor(accent)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 8) {
                    HStack {
                        ForEach(["SUN","MON","TUE","WED","THU","FRI","SAT"], id: \.self) { w in
                            Text(w).font(.caption2).foregroundColor(.gray).frame(maxWidth: .infinity)
                        }
                    }

                    // 7 columns grid
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(daysInMonth, id: \.self) { day in
                            DayCell(date: day,
                                    inCurrentMonth: Calendar.current.isDate(day, equalTo: monthAnchor, toGranularity: .month),
                                    learned: learnedDates.contains(day.startOfDay),
                                    frozen: frozenDates.contains(day.startOfDay),
                                    accent: accent,
                                    frozenColor: frozen)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: monthAnchor) {
            monthAnchor = newDate
        }
    }
}

private struct DayCell: View {
    let date: Date
    let inCurrentMonth: Bool
    let learned: Bool
    let frozen: Bool
    let accent: Color
    let frozenColor: Color

    var body: some View {
        ZStack {
            if inCurrentMonth {
                if learned {
                    Circle().fill(accent.opacity(0.9))
                } else if frozen {
                    Circle().fill(frozenColor.opacity(0.9))
                } else {
                    Circle().fill(Color.white.opacity(0.06))
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.caption)
                    .foregroundColor(.white)
            } else {
                Circle().fill(Color.clear)
                    .overlay(
                        Text("")
                    )
            }
        }
        .frame(height: 36)
    }
}
