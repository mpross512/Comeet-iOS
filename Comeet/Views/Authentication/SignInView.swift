import SwiftUI
import ComeetData

struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @Binding var submitting: Bool
    var showSignUp: () -> Void
    @State private var email = ""
    @State private var password = ""
    @State private var errorText: String?
    @State private var passwordFocused = false
    @State private var recoveringPassword = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome back").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                AuthField(title: "NetID") {
                    TextField("NetID", text: $email)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .submitLabel(.next).onSubmit { passwordFocused = true }
                }
                AuthField(title: "Password") {
                    AuthPasswordField(placeholder: "Password", password: $password, focused: $passwordFocused, onSubmit: submit)
                }
                Button("Forgot password?") { passwordFocused = false; password = ""; recoveringPassword = true }
                    .frame(minHeight: 44).disabled(submitting)
                if let errorText { AuthError(message: errorText) }
                Button(action: submit) {
                    HStack {
                        if submitting { ProgressView().tint(.white) }
                        Text(submitting ? "Signing in…" : "Sign in")
                    }
                }
                .buttonStyle(AuthPrimaryButtonStyle())
                .disabled(submitting || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                Button("New to Comeet? Create an account", action: showSignUp)
                    .frame(maxWidth: .infinity, minHeight: 44).disabled(submitting)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .disabled(submitting)
        .navigationDestination(isPresented: $recoveringPassword) {
            PasswordRecoveryView(initialEmail: AuthIdentifier.email(email), submitting: $submitting) { address in
                email = address
            }
        }
    }

    private func submit() {
        guard !submitting, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else { return }
        submitting = true
        errorText = nil
        passwordFocused = false
        let identifier = AuthIdentifier.email(email)
        Task {
            defer { submitting = false }
            do {
                try await session.signIn(email: identifier, password: password)
            } catch {
                if case APIError.http(401, _) = error {
                    errorText = "Your NetID or password didn’t match. Check them and try again."
                } else { errorText = authenticationError(error) }
            }
        }
    }
}

func authenticationError(_ error: Error) -> String {
    if error is URLError { return "Couldn’t connect. Check your internet connection and try again." }
    if case APIError.http(429, _) = error { return "Too many attempts. Please wait a moment and try again." }
    if case APIError.http(let code, _) = error, code >= 500 { return "Comeet is temporarily unavailable. Please try again shortly." }
    return error.localizedDescription
}

@MainActor @Observable
final class PasswordRecoveryState {
    enum Stage { case request, reset, complete }
    var email: String
    var resetCode = ""
    var newPassword = ""
    private(set) var stage = Stage.request
    private(set) var busy = false
    private(set) var errorMessage: String?
    private(set) var infoMessage: String?
    private(set) var resendAvailableAt = Date.distantPast
    private(set) var codeRequested = false
    private var requestedEmail: String?

    init(email: String = "") { self.email = email }

    func requestCode(repository: any ComeetRepository) async {
        guard !busy else { return }
        guard let address = validatedEmail() else { return }
        guard !(Date() < resendAvailableAt) else { return }
        busy = true; errorMessage = nil; infoMessage = nil
        defer { busy = false }
        do {
            try await repository.requestPasswordReset(email: address)
            requestedEmail = address
            email = address
            stage = .reset
            codeRequested = true
            resendAvailableAt = .now.addingTimeInterval(30)
        } catch { errorMessage = authenticationError(error) }
    }

    func useExistingCode() {
        guard !busy, let address = validatedEmail() else { return }
        requestedEmail = address; email = address; stage = .reset; codeRequested = false
        errorMessage = nil; infoMessage = nil
    }

    private func validatedEmail() -> String? {
        let address = AuthIdentifier.email(email)
        let parts = address.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."), !address.contains(where: \.isWhitespace) else {
            errorMessage = "Enter the email address you used to create your account."; return nil
        }
        return address
    }

    func reset(repository: any ComeetRepository) async {
        guard !busy, stage == .reset, let address = requestedEmail else { return }
        let code = resetCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { errorMessage = "Paste the reset code from your email."; return }
        guard PasswordPolicy.accepts(newPassword) else { errorMessage = "Your new password must meet all the requirements."; return }
        busy = true; errorMessage = nil; infoMessage = nil
        defer { busy = false }
        do {
            try await repository.resetPassword(email: address, resetCode: code, newPassword: newPassword)
            clearSecrets()
            stage = .complete
        } catch {
            if case APIError.http(400, _) = error {
                errorMessage = "The code may be invalid, expired, or already used, or your password wasn’t accepted. Check the code and requirements, or request a new code."
            } else { errorMessage = authenticationError(error) }
        }
    }

    func resendVerification(repository: any ComeetRepository) async {
        guard !busy, !(Date() < resendAvailableAt), let address = requestedEmail else { return }
        busy = true; errorMessage = nil; infoMessage = nil
        defer { busy = false }
        do {
            try await repository.resendConfirmation(email: address)
            infoMessage = "If this account exists, a verification email has been requested. Follow its link, then request a new reset code."
            resendAvailableAt = .now.addingTimeInterval(30)
        } catch { errorMessage = authenticationError(error) }
    }

    func changeEmail() {
        guard !busy else { return }
        clearSecrets(); stage = .request; requestedEmail = nil
        codeRequested = false
        errorMessage = nil; infoMessage = nil
        // Keep the cooldown across address edits to avoid accidental repeated requests.
    }
    func clearSecrets() { resetCode = ""; newPassword = "" }
}

struct PasswordRecoveryView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Binding var submitting: Bool
    @State private var recovery: PasswordRecoveryState
    @State private var passwordFocused = false
    private var onPasswordReset: (String) -> Void

    init(initialEmail: String, submitting: Binding<Bool>, onPasswordReset: @escaping (String) -> Void = { _ in }) {
        self.init(state: PasswordRecoveryState(email: initialEmail), submitting: submitting, onPasswordReset: onPasswordReset)
    }

    init(state: PasswordRecoveryState, submitting: Binding<Bool>, onPasswordReset: @escaping (String) -> Void = { _ in }) {
        _recovery = State(initialValue: state)
        _submitting = submitting
        self.onPasswordReset = onPasswordReset
    }

    var body: some View {
        @Bindable var recovery = recovery
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(recovery.stage == .complete ? "Password updated" : "Reset your password")
                    .font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                if recovery.stage == .request {
                    Text("Enter your account email and we’ll help you reset your password.").foregroundStyle(.secondary)
                    AuthField(title: "Account email") {
                        TextField("Email address", text: $recovery.email)
                            .textContentType(.username).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .submitLabel(.go).onSubmit { requestCode() }
                    }
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        VStack(alignment: .leading, spacing: 12) {
                            Button(recovery.busy ? "Requesting code…" : "Send reset code", action: requestCode)
                                .buttonStyle(AuthPrimaryButtonStyle())
                                .disabled(recovery.busy || recovery.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || context.date < recovery.resendAvailableAt)
                            if context.date < recovery.resendAvailableAt { Text("Please wait a moment before requesting another code.").font(.callout) }
                        }
                    }
                    Button("I already have a reset code") { recovery.useExistingCode() }.frame(minHeight: 44)
                } else if recovery.stage == .reset {
                    Text(recovery.codeRequested
                         ? "If there’s an account with a verified email at \(recovery.email), a reset code has been requested. Check your inbox and spam folder."
                         : "Paste the reset code from the email for \(recovery.email), then choose a new password.")
                        .foregroundStyle(.secondary)
                    AuthField(title: "Reset code") {
                        TextField("Paste the code from your email", text: $recovery.resetCode, axis: .vertical)
                            .lineLimit(2...5).textContentType(.oneTimeCode)
                            .keyboardType(.asciiCapable).textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    AuthField(title: "New password") {
                        AuthPasswordField(placeholder: "New password", password: $recovery.newPassword,
                                          focused: $passwordFocused, isNewPassword: true, onSubmit: resetPassword)
                    }
                    PasswordRequirements(password: recovery.newPassword)
                    Button(recovery.busy ? "Please wait…" : "Update password", action: resetPassword)
                        .buttonStyle(AuthPrimaryButtonStyle())
                        .disabled(recovery.resetCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || recovery.newPassword.isEmpty)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        VStack(alignment: .leading, spacing: 12) {
                            Button("Request a new code", action: requestCode)
                            Text("Haven’t verified your email? Verify it first, then request a new reset code.").font(.callout).foregroundStyle(.secondary)
                            Button("Resend verification email") {
                                perform { await recovery.resendVerification(repository: session.repository) }
                            }
                        }.disabled(recovery.busy || context.date < recovery.resendAvailableAt)
                    }
                    Button("Use a different email") { passwordFocused = false; recovery.changeEmail() }
                } else {
                    Text("You can now sign in with your new password.")
                    Button("Back to sign in") { dismiss() }.buttonStyle(AuthPrimaryButtonStyle())
                }
                if recovery.busy { ProgressView("Please wait…") }
                if let info = recovery.infoMessage { Text(info).font(.callout).foregroundStyle(.secondary) }
                if let error = recovery.errorMessage { AuthError(message: error) }
            }.padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground))
        .tint(AuthAppearance.tint)
        .navigationBarBackButtonHidden(submitting)
        .disabled(submitting)
        .onDisappear {
            if recovery.stage == .complete { onPasswordReset(recovery.email) }
            recovery.clearSecrets()
        }
    }

    private func requestCode() { perform { await recovery.requestCode(repository: session.repository) } }
    private func resetPassword() { perform { await recovery.reset(repository: session.repository) } }
    private func perform(_ operation: @escaping @MainActor () async -> Void) {
        guard !submitting, !recovery.busy else { return }
        submitting = true; passwordFocused = false
        Task { defer { submitting = false }; await operation() }
    }
}
