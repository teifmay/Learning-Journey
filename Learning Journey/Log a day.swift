//
//  Log a day.swift
//  Learning Journey
//
//  Created by Teif May on 29/04/1447 AH.
//

import SwiftUI

// MARK: - Fire Glass MVVM (Calm Liquid Glass - Brown Theme)

final class FireGlassViewModel: ObservableObject {
    // Animation phases
    @Published var specularPhase: CGFloat = -0.25
    @Published var causticPhase: CGFloat = 0
    @Published var tintPhase: CGFloat = 0

    // Tunable parameters (subtle by default)
    // Warm brown/orange ambient tint
    @Published var baseTint: Color = Color(red: 0.80, green: 0.45, blue: 0.15).opacity(0.18)

    // Durations (slow and calm)
    var specularDuration: Double = 6.0
    var causticDuration: Double = 12.0
    var tintDuration: Double = 10.0

    func startAnimations() {
        // Gentle, slow motions
        specularPhase = -0.25
        withAnimation(.easeInOut(duration: specularDuration).repeatForever(autoreverses: true)) {
            specularPhase = 0.25
        }
        withAnimation(.easeInOut(duration: causticDuration).repeatForever(autoreverses: true)) {
            causticPhase = .pi * 2
        }
        withAnimation(.easeInOut(duration: tintDuration).repeatForever(autoreverses: true)) {
            tintPhase = 1
        }
    }

    // Thickness model (adapts to size)
    func thickness(for size: CGFloat) -> (depth: Double, shadow: CGFloat, rim: Double, specular: Double, caustic: Double) {
        let n = max(0.6, min(1.8, size / 100.0))
        let depth = Double(0.6 + (n - 0.6) * 0.6)          // slightly reduced range
        let shadow = 3 + (n - 0.6) * 5                     // softer shadow
        let rim = 0.18 + (n - 0.6) * 0.08                  // softer rim
        let specular = 0.7 + (n - 1.0) * 0.15              // less intense
        let caustic = 0.6 + (n - 1.0) * 0.10               // less intense
        return (depth, shadow, rim, specular, caustic)
    }
}

struct FireGlassButton: View {
    @StateObject private var vm = FireGlassViewModel()

    var body: some View {
        LiquidGlassControl(icon: "flame.fill")
            .environmentObject(vm)
            .onAppear { vm.startAnimations() }
    }
}

private struct LiquidGlassControl: View {
    @EnvironmentObject private var vm: FireGlassViewModel
    let icon: String

    // Deep brown glass base and copper accents
    private let brownBase = Color(red: 0.10, green: 0.04, blue: 0.04)   // very dark brown
    private let brownInner = Color(red: 0.14, green: 0.06, blue: 0.06)  // inner fill
    private let copper = Color(red: 0.80, green: 0.45, blue: 0.15)

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let thickness = vm.thickness(for: size)
            let shadowRadius = thickness.shadow
            let rimOpacity = thickness.rim
            let specularIntensity = thickness.specular
            let causticIntensity = thickness.caustic

            ZStack {
                // Base “glass” body in deep brown, with subtle inner gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                brownInner,
                                brownBase
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    // soft copper glow shadow
                    .shadow(color: copper.opacity(0.25), radius: shadowRadius, x: 0, y: shadowRadius * 0.4)
                    .shadow(color: Color.black.opacity(0.50), radius: shadowRadius, x: 0, y: shadowRadius * 0.9)
                    .overlay(
                        // Ambient tint breathing very subtly
                        ambientTint(baseTint: vm.baseTint)
                            .opacity(0.18)
                            .blendMode(.plusLighter)
                    )

                // Inner depth glow (slight, to avoid over-brightness)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.06 + thickness.depth * 0.04),
                                Color.white.opacity(0.015),
                                .clear
                            ],
                            center: .center,
                            startRadius: size * 0.12,
                            endRadius: size * 0.56
                        )
                    )
                    .blendMode(.screen)

                // Copper rim light
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                copper.opacity(0.55),
                                Color.white.opacity(min(0.25, rimOpacity)),
                                copper.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(1, size * 0.012)
                    )
                    .blur(radius: 0.6)

                // Specular sweep (very subtle)
                specularLayer(size: size, intensity: specularIntensity)
                    .mask(Circle())
                    .offset(x: vm.specularPhase * size * 0.30) // small travel
                    .opacity(0.28) // toned down
                    .blendMode(.screen)

                // Caustic shimmer (barely moving, faint)
                causticLayer(size: size, intensity: causticIntensity)
                    .mask(Circle())
                    .offset(x: sin(vm.causticPhase) * size * 0.035, y: cos(vm.causticPhase * 0.8) * size * 0.025)
                    .opacity(0.035)
                    .blendMode(.screen)

                // Refractive lensing hint
                lensLayer(size: size, thickness: thickness.depth)
                    .mask(Circle())
                    .opacity(0.06 + thickness.depth * 0.04)
                    .blendMode(.overlay)

                // Icon
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.32, height: size * 0.32)
                    .foregroundStyle(Color.orange)
                    .shadow(color: .black.opacity(0.28), radius: 1.8, x: 0, y: 1)
                    .padding(size * 0.18)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Circle())
            .overlay(
                // faint halo to lift from background
                Circle()
                    .stroke(copper.opacity(0.15), lineWidth: max(1, size * 0.008))
                    .blur(radius: 1.0)
            )
        }
        .frame(width: 100, height: 100)
    }

    // MARK: - Layers

    private func ambientTint(baseTint: Color) -> some View {
        // Very slow, subtle warm tint breathing
        TimelineView(.animation) { context in
            let t = (sin(context.date.timeIntervalSinceReferenceDate / 10.0) + 1) * 0.5
            let dynamic = baseTint
                .mix(with: Color(red: 0.95, green: 0.75, blue: 0.45), by: 0.08 * t) // warm highlight
                .mix(with: Color.black, by: 0.05 * (1 - t))                          // deepen slightly
            return AnyView(
                LinearGradient(colors: [dynamic, dynamic.opacity(0.4), .clear],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .blur(radius: 1.4)
            )
        }
    }

    private func specularLayer(size: CGFloat, intensity: Double) -> some View {
        let width = size * 0.52
        let stops: [Gradient.Stop] = [
            .init(color: .white.opacity(0.0), location: 0.00),
            .init(color: .white.opacity(0.08 * intensity), location: 0.35),
            .init(color: .white.opacity(0.18 * intensity), location: 0.50),
            .init(color: .white.opacity(0.08 * intensity), location: 0.65),
            .init(color: .white.opacity(0.0), location: 1.00)
        ]
        return LinearGradient(gradient: Gradient(stops: stops), startPoint: .leading, endPoint: .trailing)
            .frame(width: width, height: size * 1.1)
            .rotationEffect(.degrees(-12))
            .blur(radius: 0.9)
    }

    private func causticLayer(size: CGFloat, intensity: Double) -> some View {
        let band = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white.opacity(0.0), location: 0.00),
                .init(color: .white.opacity(0.10 * intensity), location: 0.50),
                .init(color: .white.opacity(0.0), location: 1.00)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        return ZStack {
            band.frame(width: size * 0.20, height: size * 0.95).rotationEffect(.degrees(-22)).offset(x: size * -0.07)
            band.frame(width: size * 0.15, height: size * 0.85).rotationEffect(.degrees(-14)).offset(x: size * 0.11)
        }
        .blur(radius: 1.0)
    }

    private func lensLayer(size: CGFloat, thickness: Double) -> some View {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0.07 * thickness), location: 0.00),
                .init(color: Color.white.opacity(0.05 * thickness), location: 0.25),
                .init(color: Color.black.opacity(0.07 * thickness), location: 0.50),
                .init(color: Color.white.opacity(0.05 * thickness), location: 0.75),
                .init(color: Color.black.opacity(0.07 * thickness), location: 1.00)
            ]),
            center: .center
        )
        .rotationEffect(.degrees(-6))
        .blur(radius: 0.8 + thickness * 0.7)
    }
}

private extension Color {
    func mix(with other: Color, by amount: CGFloat) -> Color {
        let a = max(0, min(1, amount))
        return Color(uiColor: UIColor(self).mix(with: UIColor(other), by: a))
    }
}

private extension UIColor {
    func mix(with other: UIColor, by amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let a = max(0, min(1, amount))
        return UIColor(red: r1 + (r2 - r1) * a,
                       green: g1 + (g2 - g1) * a,
                       blue: b1 + (b2 - b1) * a,
                       alpha: a1 + (a2 - a1) * a)
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

    // Target learned-day counts per duration
    var targetDays: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
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

    // Completion logic: frozen days count toward the window
    private var targetDays: Int { duration.targetDays }
    private var isGoalCompleted: Bool {
        (learnedDates.count + frozenDates.count) >= targetDays
    }

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

                // Inline completion section (appears when goal is completed)
                if isGoalCompleted {
                    GoalCompletedView(
                        onSetNewGoal: {
                            // Reset progress, then open edit sheet
                            learnedDates.removeAll()
                            frozenDates.removeAll()
                            draftGoal = learningTopic
                            showEditGoalSheet = true
                        },
                        onSetSameGoal: {
                            // Reset progress only (keep goal and duration)
                            learnedDates.removeAll()
                            frozenDates.removeAll()
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut, value: isGoalCompleted)
                }

                Spacer(minLength: 12)

                // Show big circle only while the goal is NOT completed
                if !isGoalCompleted {
                    LogActionView(
                        selectedDate: $currentDate,
                        learnedDates: $learnedDates,
                        frozenDates: $frozenDates,
                        logAsLearnedAction: toggleLearnedStatus
                    )
                    .padding(.vertical, 8)
                }

                Spacer(minLength: 12)

                // Show "Log as Frozen" only while the goal is NOT completed
                if !isGoalCompleted {
                    ActionButtonsView(
                        canFreeze: frozenDates.count < maxFreezes,
                        freezesUsed: frozenDates.count,
                        maxFreezes: maxFreezes,
                        logAsFreezedAction: toggleFrozenStatus
                    )
                    .padding(.bottom, 8)
                }
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

// MARK: - Goal Completed Inline View
private struct GoalCompletedView: View {
    var onSetNewGoal: () -> Void
    var onSetSameGoal: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Icon and title
            VStack(spacing: 8) {
                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text("Well done!")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("Goal completed! Start learning again or set a new learning goal")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 8)

            // Primary action
            Button(action: onSetNewGoal) {
                Text("Set new learning goal")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(22)
            }
            .padding(.horizontal, 40)

            // Secondary action
            Button(action: onSetSameGoal) {
                Text("Set same learning goal and duration")
                    .font(.footnote)
                    .foregroundColor(Theme.accent)
            }
            .padding(.bottom, 8)
        }
        .padding(.vertical, 16)
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
