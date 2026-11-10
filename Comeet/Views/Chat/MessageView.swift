//
//  MessageView.swift
//  Comeet
//
//  Created by Michael Ross on 10/11/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import ComeetData
import WrappingHStack

/// Polls one open conversation. Failures retry with backoff instead of ending updates; only
/// cancellation (leaving the chat or backgrounding) and a signed-out session stop the loop.
@MainActor @Observable
final class MessagePollingState {
    private(set) var reconnecting = false

    static func delay(afterFailures failures: Int) -> Duration {
        guard failures > 0 else { return .seconds(2) }
        return .seconds(min(30, 2 << min(failures - 1, 4)))   // 2, 4, 8, 16, 30 seconds
    }

    func run(conversation: Conversation,
             repository: any ComeetRepository = APIConfiguration.client,
             handleError: @MainActor (any Error) -> Void = { SessionStore.shared.handle($0) },
             sleep: (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) async {
        var failures = 0
        while !Task.isCancelled {
            do {
                try await conversation.refresh(repository: repository)
                failures = 0
                reconnecting = false
            } catch {
                if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled { return }
                handleError(error)
                if error as? APIError == .signedOut { return }
                failures += 1
                reconnecting = true
            }
            do { try await sleep(Self.delay(afterFailures: failures)) } catch { return }
        }
    }
}

struct MessageView: View {
    @Environment(User.self) private var currentUser
    let conversation: Conversation
    @Environment(\.scenePhase) private var scenePhase
    @State private var polling = MessagePollingState()

    private var peer: ConversationPeer { conversation.peer }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if conversation.messages.isEmpty {
                        ContentUnavailableView("No Messages Yet", systemImage: "bubble.left.and.bubble.right",
                                               description: Text("Messages with \(peer.firstName) will appear here."))
                    }
                    ForEach(Array(conversation.messages.enumerated()), id: \.element.id) { index, message in
                        VStack(spacing: 6) {
                            if Self.startsGroup(conversation.messages, at: index) {
                                Text(message.timestamp.formatted(.chatTimestamp))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 10)
                            }
                            MessageRow(message: message, peer: peer, isMine: message.sender == currentUser.id)
                        }
                        .id(message.id)
                    }
                }
                .padding(.vertical)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: conversation.lastActivityID) {
                withAnimation { proxy.scrollTo(conversation.lastActivityID, anchor: .bottom) }
            }
        }
        .safeAreaInset(edge: .top) {
            if polling.reconnecting {
                Label("Reconnecting…", systemImage: "wifi.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
        }
        .safeAreaInset(edge: .bottom) { footer }
        .navigationTitle(peer.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            // Only offered when the profile is available; a bare avatar would look tappable.
            if let match = currentUser.matches.first(where: { $0.id == peer.id }) {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        UserView(user: match)
                    } label: {
                        ProfilePicture(userID: peer.id, width: 32, height: 32)
                    }
                    .accessibilityLabel("View \(peer.firstName)’s profile")
                }
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await polling.run(conversation: conversation)
        }
    }

    /// Show a timestamp before the first message, on a new day, or after a 30-minute gap.
    nonisolated static func startsGroup(_ messages: [MessageRecord], at index: Int) -> Bool {
        guard index > 0 else { return true }
        let previous = messages[index - 1].timestamp, current = messages[index].timestamp
        return !current.isSameDateAs(date: previous) || current.timeIntervalSince(previous) > 30 * 60
    }

    @ViewBuilder
    private var footer: some View {
        if let prompt = conversation.openPrompt {
            ResponseOptions(conversation: conversation, prompt: prompt)
                .id(prompt.id)   // A new prompt starts with a fresh selection and send ID.
        } else if !conversation.messages.isEmpty {
            Text("You’ll be able to reply when there’s a next step.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }
}

struct MessageRow: View {
    let message: MessageRecord
    let peer: ConversationPeer
    let isMine: Bool

    private var text: String { MessageText.body(of: message, peer: peer) }
    private var time: String { message.timestamp.formatted(date: .abbreviated, time: .shortened) }

    var body: some View {
        if MessageText.isSystem(message) {
            Text(verbatim: text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Comeet: \(text), \(time)")
        } else {
            HStack {
                if isMine { Spacer(minLength: 48) }
                Text(verbatim: text)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMine ? Constants.Colors.orangeTextBackgroundColor : Constants.Colors.greenColor,
                                in: RoundedRectangle(cornerRadius: 18))
                if !isMine { Spacer(minLength: 48) }
            }
            .padding(.horizontal, 12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(isMine ? "You" : peer.firstName): \(text), \(time)")
        }
    }
}

struct ResponseOptions: View {
    let conversation: Conversation
    let prompt: MessageRecord
    var messageService = MessageService()
    @State private var selectedResponse: String?
    @State private var dateSlots: [Date]?
    @State private var editingDates = false
    @State private var sending = false
    @State private var sendError: String?
    // A changed payload must never reuse the ID of an earlier (possibly committed) attempt.
    @State private var clientID = UUID()

    private var canSend: Bool {
        guard let selectedResponse, !sending else { return false }
        return selectedResponse != MessageText.dateSlotsOption || dateSlots != nil
    }

    var body: some View {
        HStack(spacing: 12) {
            WrappingHStack(prompt.responseOptions) { option in
                chip(option).padding(.vertical, 4)
            }
            sendButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 25).strokeBorder(.separator))
        .padding()
        .background(.bar)
        .sheet(isPresented: $editingDates) {
            DateSlotsSheet(initial: dateSlots ?? DateSlotsSheet.defaultSlots()) { dates in
                dateSlots = dates
                selectedResponse = MessageText.dateSlotsOption
            }
        }
        .onChange(of: selectedResponse) { clientID = UUID() }
        .onChange(of: dateSlots) { clientID = UUID() }
        .alert("Couldn’t Send Reply", isPresented: Binding(get: { sendError != nil }, set: { if !$0 { sendError = nil } })) {
            Button("OK") { sendError = nil }
        } message: { Text(sendError ?? "") }
    }

    private func chip(_ option: String) -> some View {
        let selected = selectedResponse == option
        return Button {
            if option == MessageText.dateSlotsOption {
                editingDates = true
            } else {
                selectedResponse = selected ? nil : option
            }
        } label: {
            HStack(spacing: 4) {
                if selected { Image(systemName: "checkmark").font(.footnote.bold()) }
                Text(MessageText.optionLabel(option))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .foregroundStyle(selected ? Color.white : Color.primary)
            .background(selected ? AnyShapeStyle(Constants.Colors.orangeTextBackgroundColor) : AnyShapeStyle(Color(.secondarySystemBackground)),
                        in: Capsule())
            .overlay { if !selected { Capsule().strokeBorder(.separator) } }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(sending)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(option == MessageText.dateSlotsOption ? "Opens a picker to choose three times." : "")
    }

    private var sendButton: some View {
        Button {
            Task { await send() }
        } label: {
            ZStack {
                Circle().fill(canSend || sending ? AnyShapeStyle(Constants.Colors.orangeTextBackgroundColor) : AnyShapeStyle(.quaternary))
                if sending {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(canSend ? AnyShapeStyle(Color.white) : AnyShapeStyle(.secondary))
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .accessibilityLabel(sending ? "Sending" : "Send")
    }

    private func send() async {
        guard canSend, let selectedResponse else { return }
        var response = selectedResponse
        if selectedResponse == MessageText.dateSlotsOption, let dateSlots {
            response = MessageText.encodeDateSlots(dateSlots)
        }
        sending = true
        defer { sending = false }
        do {
            let message = try await messageService.addMessage(
                conversationID: conversation.id, messageID: prompt.id, response: response, clientID: clientID)
            conversation.insert([message])   // Hides the answered prompt immediately.
        } catch {
            SessionStore.shared.handle(error)
            sendError = error.localizedDescription
        }
    }
}

struct DateSlotsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var slots: [Date]
    let onDone: ([Date]) -> Void

    init(initial: [Date], onDone: @escaping ([Date]) -> Void) {
        _slots = State(initialValue: Self.normalized(initial))
        self.onDone = onDone
    }

    /// The next three whole hours, one hour apart.
    nonisolated static func defaultSlots(from now: Date = .now, calendar: Calendar = .current) -> [Date] {
        let start = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime) ?? now
        return (0..<3).map { start.addingTimeInterval(Double($0) * 3600) }
    }

    /// Each slot starts at least an hour after the previous one.
    nonisolated static func normalized(_ slots: [Date]) -> [Date] {
        var result = Array(slots.prefix(3))
        while result.count < 3 { result.append((result.last ?? .now).addingTimeInterval(3600)) }
        for index in 1..<3 { result[index] = max(result[index], result[index - 1].addingTimeInterval(3600)) }
        return result
    }

    private func slot(_ index: Int) -> Binding<Date> {
        Binding(get: { slots[index] }, set: { value in
            var updated = slots
            updated[index] = value
            slots = Self.normalized(updated)
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Option 1", selection: slot(0), in: Date.now...)
                    DatePicker("Option 2", selection: slot(1), in: slots[0].addingTimeInterval(3600)...)
                    DatePicker("Option 3", selection: slot(2), in: slots[1].addingTimeInterval(3600)...)
                } footer: {
                    Text("Choose 3 times you’d be available for a 1-hour date. Each time starts at least an hour after the one before.")
                }
            }
            .navigationTitle("Suggest Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(slots)
                        dismiss()
                    }
                    .disabled(slots[0] < .now)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Date slots") {
    DateSlotsSheet(initial: DateSlotsSheet.defaultSlots()) { _ in }
}
