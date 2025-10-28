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
        let depth = Double(0.6 + (n - 0.6) * 0.6)
        let shadow = 3 + (n - 0.6) * 5
        let rim = 0.18 + (n - 0.6) * 0.08
        let specular = 0.7 + (n - 1.0) * 0.15
        let caustic = 0.6 + (n - 1.0) * 0.10
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

    private let brownBase = Color(red: 0.10, green: 0.04, blue: 0.04)
    private let brownInner = Color(red: 0.14, green: 0.06, blue: 0.06)
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
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [brownInner, brownBase],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: copper.opacity(0.25), radius: shadowRadius, x: 0, y: shadowRadius * 0.4)
                    .shadow(color: Color.black.opacity(0.50), radius: shadowRadius, x: 0, y: shadowRadius * 0.9)
                    .overlay(
                        ambientTint(baseTint: vm.baseTint)
                            .opacity(0.18)
                            .blendMode(.plusLighter)
                    )

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

                specularLayer(size: size, intensity: specularIntensity)
                    .mask(Circle())
                    .offset(x: vm.specularPhase * size * 0.30)
                    .opacity(0.28)
                    .blendMode(.screen)

                causticLayer(size: size, intensity: causticIntensity)
                    .mask(Circle())
                    .offset(x: sin(vm.causticPhase) * size * 0.035, y: cos(vm.causticPhase * 0.8) * size * 0.025)
                    .opacity(0.035)
                    .blendMode(.screen)

                lensLayer(size: size, thickness: thickness.depth)
                    .mask(Circle())
                    .opacity(0.06 + thickness.depth * 0.04)
                    .blendMode(.overlay)

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
                Circle()
                    .stroke(copper.opacity(0.15), lineWidth: max(1, size * 0.008))
                    .blur(radius: 1.0)
            )
        }
        .frame(width: 100, height: 100)
    }

    private func ambientTint(baseTint: Color) -> some View {
        TimelineView(.animation) { context in
            let t = (sin(context.date.timeIntervalSinceReferenceDate / 10.0) + 1) * 0.5
            let dynamic = baseTint
                .mix(with: Color(red: 0.95, green: 0.75, blue: 0.45), by: 0.08 * t)
                .mix(with: Color.black, by: 0.05 * (1 - t))
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
                    ZStack { FireGlassButton() }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 5)
                        .padding(.bottom, 20)

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

                    Text("I want to learn it in a")
                        .foregroundColor(.white)
                        .font(.title3.weight(.semibold))
                        .padding(.bottom, 10)

                    DurationPills(selected: $selectedDuration)
                        .padding(.bottom, 0)

                    Spacer()

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

// MARK: - Activity View (Calendar + Freeze + Log Day)
struct ActivityView: View {
    @Binding var learningTopic: String
    @State var duration: LearningDuration

    @State private var currentDate: Date = Date()
    @State private var learnedDates: Set<Date> = []
    @State private var frozenDates: Set<Date> = []
    @State private var showDatePicker = false

    // Navigation and edit states
    @State private var goToFullCalendar = false
    @State private var showGoalResetAlert = false
    @State private var showEditGoalSheet = false
    @State private var draftGoal: String = ""

    // New: navigate to Goal Editor (in the same file)
    @State private var navigateToGoalEditor = false
    @State private var openEditorResetsProgress = false

    private var maxFreezes: Int { duration.freezesLimit }

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
                        // Pencil flow: show warning first (custom popup)
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
                    learningTopic: learningTopic,
                    learnedDays: learnedDates.count,
                    frozenDays: frozenDates.count
                )

                if isGoalCompleted {
                    GoalCompletedView(
                        onSetNewGoal: {
                            // Change: reset progress after saving new goal
                            openEditorResetsProgress = true
                            navigateToGoalEditor = true
                        },
                        onSetSameGoal: {
                            learnedDates.removeAll()
                            frozenDates.removeAll()
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut, value: isGoalCompleted)
                }

                Spacer(minLength: 12)

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
        // Custom warning popup overlay (replaces system alert)
        .overlay {
            if showGoalResetAlert {
                GoalUpdateWarningPopup(
                    title: "Update Learning goal",
                    message: "If you update now, your streak will start over.",
                    onDismiss: { showGoalResetAlert = false },
                    onUpdate: {
                        // proceed to editor and mark reset-on-save
                        openEditorResetsProgress = true
                        showGoalResetAlert = false
                        navigateToGoalEditor = true
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.2), value: showGoalResetAlert)
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
        // Push the inline editor declared below
        .navigationDestination(isPresented: $navigateToGoalEditor) {
            LearningGoalEditorInline(
                goal: learningTopic,
                duration: duration,
                onSave: { newGoal, newDuration in
                    learningTopic = newGoal
                    duration = newDuration
                    if openEditorResetsProgress {
                        learnedDates.removeAll()
                        frozenDates.removeAll()
                    }
                    navigateToGoalEditor = false
                },
                onCancel: { navigateToGoalEditor = false }
            )
        }
        // Legacy sheet kept for reference
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

// MARK: - Inline Learning Goal Editor (same file)
private struct LearningGoalEditorInline: View {
    @State private var draftGoal: String
    @State private var draftDuration: LearningDuration

    let onSave: (_ newGoal: String, _ newDuration: LearningDuration) -> Void
    let onCancel: () -> Void

    init(goal: String,
         duration: LearningDuration,
         onSave: @escaping (_ newGoal: String, _ newDuration: LearningDuration) -> Void,
         onCancel: @escaping () -> Void) {
        _draftGoal = State(initialValue: goal)
        _draftDuration = State(initialValue: duration)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Top bar
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Learning Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        onSave(draftGoal.trimmingCharacters(in: .whitespacesAndNewlines), draftDuration)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.accent)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)

                // Content
                VStack(alignment: .leading, spacing: 20) {
                    Text("I want to learn")
                        .foregroundColor(.white)
                        .font(.title3.weight(.semibold))

                    TextField("", text: $draftGoal,
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

                    Text("I want to learn it in a")
                        .foregroundColor(.white)
                        .font(.title3.weight(.semibold))

                    DurationPills(selected: $draftDuration)
                        .padding(.top, 2)

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Goal Completed Inline View
private struct GoalCompletedView: View {
    var onSetNewGoal: () -> Void
    var onSetSameGoal: () -> Void

    var body: some View {
        VStack(spacing: 16) {
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

// MARK: - Edit Goal Sheet (legacy; not used in new flow)
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
                    ForEach(["SUN","MON","MON","TUE","WED","THU","FRI","SAT"].unique(), id: \.self) {
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
            if !learningTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(learningTopic)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            HStack(spacing: 12) {
                StatPill(icon: "flame.fill", color: Theme.accent, title: "\(learnedDays) Days learn ")
                    .frame(maxWidth: .infinity)
                StatPill(icon: "cube.fill", color: Theme.cyan, title: "\(frozenDays) Days Froze")
                    .frame(maxWidth: .infinity)
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
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .truncationMode(.middle)
                .layoutPriority(1)
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

// MARK: - Sequence Helpers
private extension Sequence where Element: Hashable {
    // Returns elements in their first-seen order with duplicates removed.
    func unique() -> [Element] {
        var seen = Set<Element>()
        var result: [Element] = []
        result.reserveCapacity(underestimatedCount)
        for element in self {
            if seen.insert(element).inserted {
                result.append(element)
            }
        }
        return result
    }
}

// MARK: - Custom warning popup
private struct GoalUpdateWarningPopup: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    let onUpdate: () -> Void

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Card
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button(action: onUpdate) {
                        Text("Update")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Preview
#Preview { OnboardingView() }
