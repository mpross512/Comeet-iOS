import SwiftUI

struct InitialView: View {
    @State private var route: AuthRoute?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("👌 Comeet")
                .font(.largeTitle.bold())
                .foregroundStyle(Constants.Colors.orangeColor)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            VStack(spacing: 20) {
                Button("Create account") { route = .signUp }
                    .buttonStyle(AuthPrimaryButtonStyle())
                Button("Already have an account? Sign in") { route = .signIn }
                    .font(.body.weight(.semibold))
                    .frame(minHeight: 44)
            }
        }
        .padding(24)
        .background(Color(uiColor: .systemGroupedBackground))
        .tint(AuthAppearance.tint)
        .sheet(item: $route) { initialRoute in
            AuthenticationView(initialRoute: initialRoute)
        }
    }
}

enum AuthRoute: String, Identifiable {
    case signIn, signUp
    var id: String { rawValue }
}

struct AuthenticationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var route: AuthRoute
    @State private var submitting = false

    init(initialRoute: AuthRoute) { _route = State(initialValue: initialRoute) }

    var body: some View {
        NavigationStack {
            Group {
                if route == .signIn {
                    SignInView(submitting: $submitting) { route = .signUp }
                } else {
                    SignUpView(submitting: $submitting) { route = .signIn }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.disabled(submitting)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .tint(AuthAppearance.tint)
        .interactiveDismissDisabled(submitting)
    }
}

struct AuthPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
            .padding(.horizontal, 12)
            .foregroundStyle(.white)
            .background(Constants.Colors.greenColor.opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45),
                        in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AuthField<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            content
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct AuthError: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(.callout)
            .foregroundStyle(.red)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Error: \(message)")
    }
}


enum AuthAppearance {
    static let tint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.61, blue: 0.07, alpha: 1)
            : UIColor(red: 0.07, green: 0.28, blue: 0.20, alpha: 1)
    })
}

enum AuthIdentifier {
    static func email(_ identifier: String) -> String {
        let value = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return "" }
        if value.contains("@") { return value }
        #if DEBUG
        return value
        #else
        return "\(value)@utdallas.edu"
        #endif
    }
}

enum PasswordPolicy {
    // Match Identity's existing 10-character minimum and default ASCII character rules.
    static func requirements(for password: String) -> [(title: String, met: Bool)] {
        let scalars = password.unicodeScalars.map(\.value)
        return [
            ("At least 10 characters", password.utf16.count >= 10),
            ("Uppercase letter (A–Z)", scalars.contains { (65...90).contains($0) }),
            ("Lowercase letter (a–z)", scalars.contains { (97...122).contains($0) }),
            ("Number (0–9)", scalars.contains { (48...57).contains($0) }),
            ("Symbol (for example ! or -)", scalars.contains { !(65...90).contains($0) && !(97...122).contains($0) && !(48...57).contains($0) })
        ]
    }
    static func accepts(_ password: String) -> Bool { requirements(for: password).allSatisfy(\.met) }
}

struct PasswordRequirements: View {
    let password: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(PasswordPolicy.requirements(for: password), id: \.title) { requirement in
                Label(requirement.title, systemImage: requirement.met ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(requirement.met ? AuthAppearance.tint : .secondary)
                    .accessibilityLabel("\(requirement.title): \(requirement.met ? "met" : "not yet met")")
            }
        }.font(.callout)
    }
}

struct AuthPasswordField: View {
    let placeholder: String
    @Binding var password: String
    @Binding var focused: Bool
    var isNewPassword = false
    var onSubmit: () -> Void
    @State private var revealed = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            PasswordTextField(text: $password, focused: $focused, revealed: revealed,
                              isNewPassword: isNewPassword, placeholder: placeholder, onSubmit: onSubmit)
                .frame(minHeight: 44)
            Button(revealed ? "Hide" : "Show") { revealed.toggle() }
                .font(.callout.weight(.semibold)).fixedSize()
                .frame(minHeight: 44)
                .accessibilityLabel(revealed ? "Hide password" : "Show password")
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { revealed = false } }
    }
}

// A single native field preserves the password, selection, and AutoFill identity
// when Show/Hide changes secure entry; switching SwiftUI field types recreates it.
struct PasswordTextField: UIViewRepresentable {
    @Environment(\.isEnabled) private var enabled
    @Binding var text: String
    @Binding var focused: Bool
    var revealed: Bool
    var isNewPassword: Bool
    var placeholder: String
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        updateField(field)
        return field
    }
    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        updateField(field)
        let focus = $focused
        DispatchQueue.main.async { [weak field] in
            guard let field, field.window != nil else { return }
            if focus.wrappedValue && !field.isFirstResponder { field.becomeFirstResponder() }
            else if !focus.wrappedValue && field.isFirstResponder { field.resignFirstResponder() }
        }
    }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextField, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 200, height: max(44, uiView.intrinsicContentSize.height))
    }
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func updateField(_ field: UITextField) {
        if field.isSecureTextEntry == revealed {
            let selection = field.selectedTextRange.map {
                (field.offset(from: field.beginningOfDocument, to: $0.start), field.offset(from: field.beginningOfDocument, to: $0.end))
            }
            field.isSecureTextEntry = !revealed
            field.text = text
            if let selection,
               let start = field.position(from: field.beginningOfDocument, offset: selection.0),
               let end = field.position(from: field.beginningOfDocument, offset: selection.1) {
                field.selectedTextRange = field.textRange(from: start, to: end)
            }
        } else if field.text != text { field.text = text }
        field.placeholder = placeholder
        field.isEnabled = enabled
        field.accessibilityLabel = placeholder
        field.textContentType = isNewPassword ? .newPassword : .password
        field.passwordRules = isNewPassword
            ? UITextInputPasswordRules(descriptor: "minlength: 10; required: lower; required: upper; required: digit; required: special;") : nil
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.returnKeyType = .go
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
    }

    @MainActor final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PasswordTextField
        init(parent: PasswordTextField) { self.parent = parent }
        @objc func changed(_ field: UITextField) { parent.text = field.text ?? "" }
        func textFieldDidBeginEditing(_ textField: UITextField) { if !parent.focused { parent.focused = true } }
        func textFieldDidEndEditing(_ textField: UITextField) { if parent.focused { parent.focused = false } }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool { parent.onSubmit(); return false }
    }
}
