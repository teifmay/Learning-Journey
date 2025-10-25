//
//  Log a day.swift
//  Learning Journey
//
//  Created by Teif May on 29/04/1447 AH.
//

import SwiftUI

struct FireGlassButton: View {
    @State private var isHovering = false
    @State private var isShining = false
    @State private var shinePhase: CGFloat = -1
    let customBrown = Color(red: 0.2, green: 0.08, blue: 0.08)

    var body: some View {
        Image(systemName: "flame.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .padding(20)
            .foregroundColor(.orange)
            .background(
                ZStack {
                    Circle().fill(customBrown)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                        .padding(1)
                        .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 5)
                    shineGradient
                        .mask(Circle())
                        .opacity(0.9)
                        // Sweep from left (-1) to right (+1)
                        .offset(x: shinePhase * 120)
                        .blur(radius: 0.5)
                }
            )
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .scaleEffect(1.02) // subtle constant “alive” feel
            .onAppear {
                // Continuous shine sweep
                shinePhase = -1
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    shinePhase = 1
                }
            }
    }

    private var shineGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white.opacity(0.0), location: 0.0),
                .init(color: .white.opacity(0.85), location: 0.45),
                .init(color: .white.opacity(0.0), location: 0.9)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 200, height: 200)
    }
}

// MARK: - Duration model
enum LearningDuration: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    var freezesLimit: Int {
        switch self {
        case .week: return 2
        case .month: return 8
        case .year: return 96
        }
    }
}

// MARK: - OnboardingView
struct OnboardingView: View {
    @State private var goal: String = ""
    @State private var selectedDuration: LearningDuration = .week
    @State private var navigateToActivity = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    // Fire button (visual only)
                    ZStack { FireGlassButton() }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 5)
                        .padding(.bottom, 20)

                    // Hello text
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Hello Learner")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("This app will help you learn everyday!")
                            .font(.callout)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 32)

                    // Goal input
                    Text("I want to learn")
                        .foregroundColor(.white)
                        .font(.title3.weight(.semibold))
                        .padding(.bottom, 6)

                    TextField("", text: $goal,
                              prompt: Text("Write your goal...")
                                .font(.callout)
                                .foregroundColor(.gray))
                        .font(.title3)
                        .foregroundColor(.white)
                        .tint(.white)
                        .padding(.bottom, 8)

                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray)
                        .opacity(0.3)
                        .padding(.bottom, 20)

                    // Duration picker like your screenshot
                    Text("I want to learn it in a")
                        .foregroundColor(.white)
                        .font(.title3.weight(.semibold))
                        .padding(.bottom, 10)

                    DurationPills(selected: $selectedDuration)
                        .padding(.bottom, 0)

                    Spacer()

                    // Start button centered near bottom
                    Button {
                        navigateToActivity = true
                    } label: {
                        Text("Start learning")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.9)], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(24)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .navigationDestination(isPresented: $navigateToActivity) {
                ActivityView(learningTopic: $goal, duration: selectedDuration)
            }
        }
    }
}

private struct DurationPills: View {
    @Binding var selected: LearningDuration

    var body: some View {
        HStack(spacing: 12) {
            ForEach(LearningDuration.allCases) { option in
                let isSelected = option == selected
                Button {
                    selected = option
                } label: {
                    Text(option.title)
                        .font(.body.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(
                            Capsule()
                                .fill(isSelected ? Theme.accent : Color.white.opacity(0.08))
                        )
                        .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Theme.accent.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Activity View (التقويم + Freeze + Log Day)
struct ActivityView: View {
    @Binding var learningTopic: String
    let duration: LearningDuration

    @State private var currentDate: Date = Date()
    @State private var learnedDates: Set<Date> = []
    @State private var frozenDates: Set<Date> = []
    @State private var showDatePicker = false

    // Navigation and edit states
    @State private var goToFullCalendar = false
    @State private var showGoalResetAlert = false
    @State private var showEditGoalSheet = false
    @State private var draftGoal: String = ""

    private var maxFreezes: Int { duration.freezesLimit }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                TitleBar(
                    calendarTapped: { goToFullCalendar = true },
                    editTapped: {
                        draftGoal = learningTopic
                        showGoalResetAlert = true
                    }
                )

                CalendarCard(
                    currentDate: $currentDate,
                    learnedDates: $learnedDates,
                    frozenDates: $frozenDates,
                    showDatePicker: $showDatePicker,
                    title: currentDate.formatted(.dateTime.year().month(.wide))
                )

                SummaryView(
                    learningTopic: learningTopic.isEmpty ? "SwiftUI" : learningTopic,
                    learnedDays: learnedDates.count,
                    frozenDays: frozenDates.count
                )

                Spacer(minLength: 12)

                // Make the big circle a tappable "Log as Learned" button
                LogActionView(
                    selectedDate: $currentDate,
                    learnedDates: $learnedDates,
                    frozenDates: $frozenDates,
                    logAsLearnedAction: toggleLearnedStatus
                )
                .padding(.vertical, 8)

                Spacer(minLength: 12)

                // Keep only the "Log as Frozen" rectangular button
                ActionButtonsView(
                    canFreeze: frozenDates.count < maxFreezes,
                    freezesUsed: frozenDates.count,
                    maxFreezes: maxFreezes,
                    logAsFreezedAction: toggleFrozenStatus
                )
                .padding(.bottom, 8)
            }
            .safeAreaPadding()
        }
        .foregroundColor(.white)
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .center) {
            if showDatePicker {
                DatePickerOverlay(currentDate: $currentDate, showDatePicker: $showDatePicker)
            }
        }
        .navigationDestination(isPresented: $goToFullCalendar) {
            FullCalendarView(
                learnedDates: learnedDates,
                frozenDates: frozenDates,
                accent: Theme.accent,
                frozen: Theme.cyan
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Change goal?", isPresented: $showGoalResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Change & Reset Streak", role: .destructive) {
                // Clear streaks, then open sheet to edit goal
                learnedDates.removeAll()
                frozenDates.removeAll()
                showEditGoalSheet = true
            }
        } message: {
            Text("Changing your goal will reset your current streak and frozen days.")
        }
        .sheet(isPresented: $showEditGoalSheet) {
            EditGoalSheet(
                draft: $draftGoal,
                onCancel: { showEditGoalSheet = false },
                onSave: {
                    learningTopic = draftGoal.trimmingCharacters(in: .whitespacesAndNewlines)
                    showEditGoalSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Actions
    private func toggleLearnedStatus() {
        let day = currentDate.startOfDay
        if learnedDates.contains(day) {
            learnedDates.remove(day)
        } else {
            learnedDates.insert(day)
            frozenDates.remove(day)
        }
    }

    private func toggleFrozenStatus() {
        let day = currentDate.startOfDay
        if frozenDates.contains(day) {
            frozenDates.remove(day)
        } else if frozenDates.count < maxFreezes {
            frozenDates.insert(day)
            learnedDates.remove(day)
        }
    }
}

// MARK: - TitleBar (Navigation title with two circular buttons)
private struct TitleBar: View {
    let calendarTapped: () -> Void
    let editTapped: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text("Activity")
                .font(.largeTitle.bold())
            Spacer()
            HStack(spacing: 12) {
                CircleIconButton(systemName: "calendar", action: calendarTapped)
                CircleIconButton(systemName: "pencil.and.outline", action: editTapped)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal)
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Theme.card)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Goal Sheet
private struct EditGoalSheet: View {
    @Binding var draft: String
    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.white.opacity(0.25)).frame(width: 44, height: 5).padding(.top, 8)
            Text("New Learning Goal")
                .font(.headline)
                .foregroundColor(.white)
            TextField("Enter your new goal", text: $draft)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .foregroundColor(.white)
                .tint(.white)
            HStack {
                Button("Cancel", action: onCancel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.25))
                    .cornerRadius(12)
                Button("Save", action: onSave)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - باقي المكونات المساعدة
private struct CalendarCard: View {
    @Binding var currentDate: Date
    @Binding var learnedDates: Set<Date>
    @Binding var frozenDates: Set<Date>
    @Binding var showDatePicker: Bool
    let title: String

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: currentDate)
        else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { showDatePicker = true } label: {
                    HStack(spacing: 6) {
                        Text(title).font(.headline)
                        Image(systemName: "chevron.down").font(.caption)
                    }
                }
                Spacer()
                HStack(spacing: 18) {
                    Button { changeWeek(by: -1) } label: {
                        Image(systemName: "chevron.left").foregroundColor(Theme.accent)
                    }
                    Button { changeWeek(by: 1) } label: {
                        Image(systemName: "chevron.right").foregroundColor(Theme.accent)
                    }
                }
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                HStack {
                    ForEach(["SUN","MON","TUE","WED","THU","FRI","SAT"], id: \.self) {
                        Text($0).font(.caption2).foregroundColor(.gray).frame(maxWidth: .infinity)
                    }
                }
                HStack(spacing: 10) {
                    ForEach(weekDays, id: \.self) { day in
                        Button { currentDate = day } label: {
                            Text(day.toString("d"))
                                .font(.headline)
                                .frame(width: 36, height: 36)
                                .background(dotBackground(for: day))
                                .clipShape(Circle())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 14)
        .background(Theme.card)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }

    private func dotBackground(for day: Date) -> some View {
        let d = day.startOfDay
        let sel = currentDate.startOfDay
        return ZStack {
            if learnedDates.contains(d) { Circle().fill(Theme.accent) }
            else if frozenDates.contains(d) { Circle().fill(Theme.cyan) }
            if d == sel { Circle().stroke(Theme.accent, lineWidth: 2) }
        }
    }

    private func changeWeek(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: amount, to: currentDate) {
            currentDate = newDate
        }
    }
}

private struct DatePickerOverlay: View {
    @Binding var currentDate: Date
    @Binding var showDatePicker: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea().onTapGesture { showDatePicker = false }
            VStack(spacing: 16) {
                DatePicker("Select a date", selection: $currentDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(Theme.accent)
                Button("Done") { showDatePicker = false }
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .cornerRadius(10)
            }
            .padding(24)
            .background(Theme.background)
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }
}

private struct SummaryView: View {
    let learningTopic: String
    let learnedDays: Int
    let frozenDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(learningTopic).font(.subheadline).foregroundColor(.gray)
            HStack(spacing: 12) {
                StatPill(icon: "flame.fill", color: Theme.accent, title: "\(learnedDays) Days Learned")
                StatPill(icon: "cube.fill", color: Theme.cyan, title: "\(frozenDays) Days Frozen")
            }
        }
        .padding()
        .background(Theme.card)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

private struct StatPill: View {
    let icon: String
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(8)
                .background(color.opacity(0.9))
                .clipShape(Circle())
            Text(title).font(.headline)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(color.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct LogActionView: View {
    @Binding var selectedDate: Date
    @Binding var learnedDates: Set<Date>
    @Binding var frozenDates: Set<Date>
    let logAsLearnedAction: () -> Void

    var body: some View {
        let day = selectedDate.startOfDay
        Button(action: logAsLearnedAction) {
            ZStack {
                if learnedDates.contains(day) {
                    Circle().strokeBorder(Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [10]))
                    VStack(spacing: 6) {
                        Text("Learned").font(.title.bold()).foregroundColor(Theme.accent)
                        Text("Today").font(.title3).foregroundColor(.gray)
                    }
                } else if frozenDates.contains(day) {
                    Circle().stroke(Theme.cyan, lineWidth: 2)
                    VStack(spacing: 6) {
                        Text("Day").font(.title3).foregroundColor(.gray)
                        Text("Frozen").font(.title.bold()).foregroundColor(.white)
                    }
                } else {
                    Circle().fill(Theme.accent)
                    Text("Log as Learned").font(.title.bold()).foregroundColor(.white)
                }
            }
            .frame(width: 240, height: 240)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log as Learned")
    }
}

private struct ActionButtonsView: View {
    let canFreeze: Bool
    let freezesUsed: Int
    let maxFreezes: Int
    let logAsFreezedAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Only the "Log as Frozen" rectangular button remains
            Button(action: logAsFreezedAction) {
                Text("Log as Frozen")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canFreeze ? Theme.cyan.opacity(0.25) : Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .foregroundColor(canFreeze ? Theme.cyan : .gray)
            }
            .disabled(!canFreeze)
            Text("\(freezesUsed) out of \(maxFreezes) Freezes used")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

// MARK: - Theme
private enum Theme {
    static let background = Color.black
    static let card = Color.gray.opacity(0.18)
    static let accent = Color.orange
    static let cyan = Color.cyan
}

// MARK: - Date Helpers
extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    func toString(_ format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: self)
    }
}

// MARK: - Preview
#Preview { OnboardingView() }
