import SwiftUI

struct SignUpView: View {
    @Environment(SessionStore.self) private var session
    @Binding var submitting: Bool
    var showSignIn: () -> Void
    @State private var netID = ""
    @State private var password = ""
    @State private var errorText: String?
    @State private var passwordFocused = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Create your account").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                AuthField(title: "NetID") {
                    TextField("Enter your NetID", text: $netID)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .submitLabel(.next).onSubmit { passwordFocused = true }
                }
                AuthField(title: "Password") {
                    AuthPasswordField(placeholder: "Create a password", password: $password,
                                      focused: $passwordFocused, isNewPassword: true, onSubmit: submit)
                }
                PasswordRequirements(password: password)
                if let errorText { AuthError(message: errorText) }
                Button(action: submit) {
                    HStack {
                        if submitting { ProgressView().tint(.white) }
                        Text(submitting ? "Creating account…" : "Create account")
                    }
                }
                .buttonStyle(AuthPrimaryButtonStyle())
                .disabled(submitting || netID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                Button("Already have an account? Sign in", action: showSignIn)
                    .frame(maxWidth: .infinity, minHeight: 44).disabled(submitting)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .disabled(submitting)
    }

    private func submit() {
        guard !submitting, !netID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.isEmpty else { return }
        let identifier = netID.trimmingCharacters(in: .whitespacesAndNewlines)
        #if !DEBUG
        let local = identifier.lowercased().hasSuffix("@utdallas.edu") ? String(identifier.dropLast("@utdallas.edu".count)) : identifier
        guard local.count == 9 && !local.contains("@") else { errorText = "Please enter a valid 9 character NetID."; return }
        #endif
        guard PasswordPolicy.accepts(password) else { errorText = "Your password must meet all the requirements below the password field."; return }
        submitting = true
        errorText = nil
        passwordFocused = false
        Task {
            defer { submitting = false }
            do {
                try await session.signUp(email: AuthIdentifier.email(identifier), password: password)
            } catch { errorText = authenticationError(error) }
        }
    }
}
