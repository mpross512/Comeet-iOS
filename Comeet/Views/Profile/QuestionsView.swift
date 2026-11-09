import SwiftUI
import ComeetData

struct RaceEthnicitySelection {
    var selected: Set<String> = []
    var selfDescription = ""

    init(value: String?) {
        for part in (value ?? "").components(separatedBy: "; ") {
            if Constants.SetupQuestions.raceEthnicityOptions.contains(part) { selected.insert(part) }
            else if !part.isEmpty { selfDescription += selfDescription.isEmpty ? part : "; " + part }
        }
    }
    var value: String? {
        var parts = Constants.SetupQuestions.raceEthnicityOptions.filter { selected.contains($0) }
        if !selfDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(selfDescription) }
        return parts.isEmpty ? nil : parts.joined(separator: "; ")
    }
}

// Drafts belong to the editor; only an explicit save commits an answer to the session.
@MainActor @Observable
final class AttributeQuestionnaire {
    struct Answer {
        var option: String?
        var importance = 3
        var race: RaceEthnicitySelection?
    }

    let questions = Constants.SetupQuestions.questions
    let isSingleQuestion: Bool
    private(set) var index = 0
    private(set) var saving = false
    private var answers: [String: Answer] = [:]
    private var loaded = false

    init(category: String? = nil, startIndex: Int = 0) {
        if let category, let index = questions.firstIndex(where: { $0.category == category }) {
            self.index = index
            isSingleQuestion = true
        } else {
            index = min(max(0, startIndex), questions.count - 1)
            isSingleQuestion = false
        }
    }

    var question: Constants.SetupQuestions.Question { questions[index] }
    var isLastQuestion: Bool { index == questions.count - 1 }
    var selectedOption: String? {
        get {
            if question.isFreeText, let race = answers[question.category]?.race { return race.value }
            return answers[question.category]?.option
        }
        set {
            var answer = answers[question.category] ?? Answer()
            answer.option = newValue
            if question.isFreeText { answer.race = RaceEthnicitySelection(value: newValue) }
            answers[question.category] = answer
        }
    }
    private var raceSelection: RaceEthnicitySelection {
        answers[question.category]?.race ?? RaceEthnicitySelection(value: answers[question.category]?.option)
    }
    var raceSelfDescription: String {
        get { raceSelection.selfDescription }
        set { var selection = raceSelection; selection.selfDescription = newValue; setRaceSelection(selection) }
    }
    func isRaceOptionSelected(_ option: String) -> Bool { raceSelection.selected.contains(option) }
    func toggleRaceOption(_ option: String) {
        var selection = raceSelection
        if selection.selected.contains(option) { selection.selected.remove(option) }
        else { selection.selected.insert(option) }
        setRaceSelection(selection)
    }
    private func setRaceSelection(_ selection: RaceEthnicitySelection) {
        var answer = answers[question.category] ?? Answer()
        answer.race = selection; answer.option = selection.value
        answers[question.category] = answer
    }
    var importance: Int {
        get { answers[question.category]?.importance ?? 3 }
        set { answers[question.category, default: Answer()].importance = min(5, max(1, newValue)) }
    }

    func load(_ attributes: [Attribute]) {
        guard !loaded else { return }
        loaded = true
        for question in questions {
            if let saved = attributes.first(where: { $0.name == question.category }),
               (question.options.contains(saved.value) || (question.isFreeText && !saved.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) {
                answers[question.category] = Answer(option: saved.value, importance: saved.importance)
            }
        }
    }

    func loadDrafts(_ records: [AttributeRecord]) {
        for record in records {
            guard let question = questions.first(where: { $0.category == record.name }),
                  question.isFreeText || question.options.contains(record.value) else { continue }
            answers[record.name] = Answer(option: record.value, importance: min(5, max(1, record.importance)))
        }
    }

    var canSave: Bool {
        guard let selectedOption else { return false }
        return !selectedOption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedOption.count <= 500
    }

    func saveAnswer(in session: SessionStore, onboarding: Bool = false) async throws -> Bool {
        guard !saving, canSave, let selectedOption else { return false }
        saving = true
        defer { saving = false }
        let answer = Attribute(name: question.category, importance: importance, value: selectedOption.trimmingCharacters(in: .whitespacesAndNewlines))
        var attributes = onboarding ? session.draft.attributeModels : session.currentUser.attributes
        if let existing = attributes.firstIndex(where: { $0.name == answer.name }) {
            attributes[existing] = answer
        } else {
            attributes.append(answer)
        }
        if onboarding {
            session.draft.attributes = attributes.map { AttributeRecord(name: $0.name, importance: $0.importance, value: $0.value) }
            if session.draftSaveError != nil { throw OnboardingSaveError() }
        } else { try await session.saveAttributes(attributes) }
        return true
    }

    // Returns true when the questionnaire is complete. Skip uses the same navigation without saving.
    func advance() -> Bool {
        guard !saving else { return false }
        if isSingleQuestion || isLastQuestion { return true }
        index += 1
        return false
    }

    func back() {
        guard !saving, !isSingleQuestion, index > 0 else { return }
        index -= 1
    }
}

struct QuestionsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var isPresented: Bool
    @State private var flow = AttributeQuestionnaire()
    @State private var goingBack = false
    @State private var saveError: String?
    private let onComplete: (() -> Void)?
    private let onboarding: Bool

    init(isPresented: Binding<Bool>, flow: AttributeQuestionnaire = AttributeQuestionnaire(),
         onComplete: (() -> Void)? = nil, onboarding: Bool = false) {
        _isPresented = isPresented
        _flow = State(initialValue: flow)
        self.onComplete = onComplete
        self.onboarding = onboarding
    }

    private var transition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: goingBack ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: goingBack ? .trailing : .leading).combined(with: .opacity))
    }

    var body: some View {
        Group {
            if flow.isSingleQuestion {
                questionContent
            } else {
                NavigationStack { questionContent }
            }
        }
        .tint(AttributeAppearance.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(flow.saving)
        .onAppear {
            if onboarding {
                flow = AttributeQuestionnaire(startIndex: session.draft.attributeIndex)
                flow.load(session.draft.attributeModels)
                flow.loadDrafts(session.draft.attributeDrafts)
            } else { flow.load(session.currentUser.attributes) }
        }
        .onChange(of: flow.index) { _, index in if onboarding { session.draft.attributeIndex = index } }
        .onChange(of: flow.selectedOption) { _, _ in persistOnboardingAnswerDraft() }
        .onChange(of: flow.importance) { _, _ in persistOnboardingAnswerDraft() }
        .onDisappear { persistOnboardingAnswerDraft() }
        .alert("Could not save answer", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "") }
    }

    private var questionContent: some View {
        VStack(spacing: 0) {
            if !flow.isSingleQuestion { progressHeader }
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(flow.question.question)
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                        if flow.question.isFreeText {
                            Text("Select all that apply. You can also describe another background, or leave this question unanswered.")
                                .font(.callout).foregroundStyle(.secondary)
                            VStack(spacing: 10) {
                                ForEach(flow.question.options, id: \.self) { option in answerRow(option) }
                            }
                            Text("Another background (optional)").font(.headline)
                            TextField("Describe your background", text: Binding(get: { flow.raceSelfDescription }, set: { flow.raceSelfDescription = $0 }), axis: .vertical)
                                .lineLimit(2...6).padding(16)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            Text("\(flow.selectedOption?.count ?? 0) / 500 characters").font(.caption).foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(flow.question.options, id: \.self) { option in
                                    answerRow(option)
                                }
                            }
                        }
                        importanceControl
                        Text(onboarding ? "Continue includes this answer in your profile draft. Skip leaves it out unless you already saved an answer." : (flow.isSingleQuestion ? "Save your changes, or cancel to keep your current answer." : "Continue saves your answer. Skip leaves it unchanged."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, flow.isSingleQuestion ? 16 : 0)
                    .padding(.bottom, 24)
                }
                .id(flow.index)
                .transition(transition)
            }
            .clipped()
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom, spacing: 0) { navigationControls }
        .navigationTitle(flow.isSingleQuestion ? flow.question.title : "Values & Lifestyle")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(flow.isSingleQuestion)
        .toolbar {
            if flow.isSingleQuestion {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(flow.saving)
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { isPresented = false }
                        .labelStyle(.iconOnly)
                        .disabled(flow.saving)
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Question \(flow.index + 1) of \(flow.questions.count)")
                Spacer()
                if !dynamicTypeSize.isAccessibilitySize { Text(flow.question.title) }
            }
            .font(dynamicTypeSize.isAccessibilitySize ? .caption : .subheadline)
            .foregroundStyle(.secondary)
            ProgressView(value: Double(flow.index + 1), total: Double(flow.questions.count))
                .accessibilityLabel("Questionnaire progress")
                .accessibilityValue("Question \(flow.index + 1) of \(flow.questions.count)")
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: flow.index)
        }
        .padding()
    }

    private func answerRow(_ option: String) -> some View {
        let selected = flow.question.isFreeText ? flow.isRaceOptionSelected(option) : flow.selectedOption == option
        let symbol = flow.question.isFreeText ? (selected ? "checkmark.square.fill" : "square") : (selected ? "checkmark.circle.fill" : "circle")
        return Button {
            if flow.question.isFreeText { flow.toggleRaceOption(option) }
            else { flow.selectedOption = option }
        } label: {
            HStack(spacing: 12) {
                Text(option)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: symbol)
                    .foregroundStyle(selected ? AttributeAppearance.accent : Color.secondary)
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(selected ? AttributeAppearance.accent.opacity(0.1) : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? AttributeAppearance.accent : Color.clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(flow.saving)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var importanceControl: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(flow.question.importancePrompt)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(AttributeImportance.label(for: flow.importance))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AttributeAppearance.accent)
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        flow.importance = level
                    } label: {
                        Text("\(level)")
                            .font(.body.weight(.semibold))
                            .frame(minWidth: 44, minHeight: 44)
                            .background(flow.importance == level ? AttributeAppearance.accent : Color(.tertiarySystemFill),
                                        in: Circle())
                            .foregroundStyle(flow.importance == level ? Color(.systemBackground) : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AttributeImportance.label(for: level))
                    .accessibilityValue("\(level) of 5")
                    .accessibilityAddTraits(flow.importance == level ? .isSelected : [])
                }
            }
            HStack(alignment: .top) {
                Text("Not important")
                Spacer()
                Text("Very important")
                    .multilineTextAlignment(.trailing)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .disabled(flow.saving)
        .accessibilityElement(children: .contain)
    }

    private var navigationControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                if !flow.isSingleQuestion {
                    Button("Back") { navigate(back: true) }
                        .disabled(flow.index == 0 || flow.saving)
                        .frame(minHeight: 44)
                }
                Button {
                    Task {
                        do {
                            if try await flow.saveAnswer(in: session, onboarding: onboarding) {
                                if flow.isSingleQuestion { dismiss() }
                                else { navigate(back: false) }
                            }
                        } catch {
                            session.handle(error)
                            saveError = error.localizedDescription
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if flow.saving { ProgressView().tint(Color(.systemBackground)) }
                        Text(flow.isSingleQuestion ? "Save Changes" : (flow.isLastQuestion ? "Save & Finish" : "Continue"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(Color(.systemBackground))
                }
                .buttonStyle(.borderedProminent)
                .disabled(!flow.canSave || flow.saving)
            }
            if !flow.isSingleQuestion {
                Button(flow.isLastQuestion ? "Skip & Finish" : "Skip") { navigate(back: false) }
                    .font(.subheadline)
                    .frame(minHeight: 44)
                    .disabled(flow.saving)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .background(.bar)
    }

    private func navigate(back: Bool) {
        goingBack = back
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.25)) {
            if back {
                flow.back()
            } else if flow.advance() {
                if onboarding { session.draft.attributeIndex = 0 }
                if let onComplete { onComplete() }
                else { isPresented = false }
            }
        }
    }

    private func persistOnboardingAnswerDraft() {
        guard onboarding else { return }
        let option = flow.selectedOption ?? ""
        let answer = AttributeRecord(name: flow.question.category, importance: flow.importance, value: option)
        var drafts = session.draft.attributeDrafts
        drafts.removeAll { $0.name == answer.name }
        drafts.append(answer)
        session.draft.attributeDrafts = drafts
    }

}

struct OnboardingSaveError: LocalizedError {
    var errorDescription: String? { "Your progress couldn’t be saved on this device. Please try again before leaving." }
}

private enum AttributeAppearance {
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.48, green: 0.82, blue: 0.64, alpha: 1)
            : UIColor(red: 0.07, green: 0.28, blue: 0.20, alpha: 1)
    })
}

enum AttributeImportance {
    private static let labels = [
        "Not important", "Slightly important", "Somewhat important", "Important", "Very important"
    ]

    static func label(for value: Int) -> String { labels[min(5, max(1, value)) - 1] }
}

#Preview {
    QuestionsView(isPresented: .constant(true))
        .environment(SessionStore.shared)
}

// Counts only questionnaire topics; unrelated/legacy attributes never determine the entry screen.
struct PersonalAttributesSummary {
    let attributes: [Attribute]

    func answer(for category: String) -> Attribute? {
        attributes.first { $0.name == category && !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var answeredCount: Int {
        Constants.SetupQuestions.questions.filter { answer(for: $0.category) != nil }.count
    }
    var hasSavedAnswers: Bool { answeredCount > 0 }
}

struct PersonalAttributesView: View {
    @Environment(SessionStore.self) private var session
    @Binding var isPresented: Bool
    @State private var showsOverview: Bool

    init(isPresented: Binding<Bool>, attributes: [Attribute]) {
        _isPresented = isPresented
        _showsOverview = State(initialValue: PersonalAttributesSummary(attributes: attributes).hasSavedAnswers)
    }

    var body: some View {
        Group {
            if showsOverview {
                overview
            } else {
                QuestionsView(isPresented: $isPresented, onComplete: { showsOverview = true })
            }
        }
        .tint(AttributeAppearance.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var overview: some View {
        let summary = PersonalAttributesSummary(attributes: session.currentUser.attributes)
        return NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What matters to you")
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text("Tap a topic to edit your answer and importance.")
                            .foregroundStyle(.secondary)
                        Text("\(summary.answeredCount) of \(Constants.SetupQuestions.questions.count) answered")
                            .font(.subheadline.weight(.medium))
                        ProgressView(value: Double(summary.answeredCount),
                                     total: Double(Constants.SetupQuestions.questions.count))
                            .accessibilityLabel("Values & Lifestyle completion")
                            .accessibilityValue("\(summary.answeredCount) of \(Constants.SetupQuestions.questions.count) answered")
                    }
                    .padding(.vertical, 8)
                }
                Section("Your answers") {
                    ForEach(Constants.SetupQuestions.questions, id: \.category) { question in
                        NavigationLink(value: question.category) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(question.title)
                                    .font(.headline)
                                if let answer = summary.answer(for: question.category) {
                                    Text(answer.value)
                                        .foregroundStyle(.secondary)
                                    Text(AttributeImportance.label(for: answer.importance))
                                        .font(.caption)
                                        .foregroundStyle(AttributeAppearance.accent)
                                } else {
                                    Text("Not answered")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                Section {
                    Button("Review all questions") { showsOverview = false }
                        .frame(minHeight: 44)
                }
            }
            .navigationTitle("Values & Lifestyle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
            .navigationDestination(for: String.self) { category in
                QuestionsView(isPresented: $isPresented, flow: AttributeQuestionnaire(category: category))
            }
        }
    }
}
