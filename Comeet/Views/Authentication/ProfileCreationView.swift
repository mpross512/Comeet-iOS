import SwiftUI
import ComeetData

struct OnboardingDraft: Codable, Equatable {
    var step = 0
    var firstName = ""
    var lastName = ""
    var birthdate = Calendar.current.startOfDay(for: Date())
    var graduationYear = ""
    var major = ""
    var photo: Data?

    func validationMessage(for step: Int) -> String? {
        if step == 0 {
            if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Enter your first name to continue." }
            if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Enter your last name to continue." }
            if firstName.count > 100 || lastName.count > 100 { return "Names must be 100 characters or fewer." }
            if birthdate > Date() { return "Choose a birthdate that isn’t in the future." }
        } else if step == 1 {
            if major.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Select your major to continue." }
            guard let year = Int(graduationYear), (1900...2200).contains(year) else {
                return "Enter a graduation year between 1900 and 2200."
            }
        }
        return nil
    }

    var fields: ProfileFields {
        ProfileFields(firstName: firstName, lastName: lastName, birthdate: WireDates.birthday(birthdate),
                      graduationYear: Int(graduationYear) ?? 0, major: major, bio: "")
    }
}

struct OnboardingDraftStore {
    let directory: URL
    init(directory: URL = URL.applicationSupportDirectory.appending(path: "Onboarding", directoryHint: .isDirectory)) {
        self.directory = directory
    }
    private func url(_ accountID: UUID) -> URL { directory.appending(path: "\(accountID.uuidString).json") }
    func load(accountID: UUID) throws -> OnboardingDraft? {
        let file = url(accountID)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return try JSONDecoder().decode(OnboardingDraft.self, from: Data(contentsOf: file))
    }
    func save(_ draft: OnboardingDraft, accountID: UUID) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var location = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try location.setResourceValues(values)
        try JSONEncoder().encode(draft).write(to: url(accountID), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    func remove(accountID: UUID) throws {
        let file = url(accountID)
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
    }
}

struct ProfileCreationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @State private var choosingPhoto = false
    @State private var saving = false
    @State private var errorText: String?
    @State private var showingVerification = false
    @State private var choosingMajor = false
    @State private var majorSearch = ""

    private var step: Int { min(max(session.draft.step, 0), 2) }
    private var title: String { ["About you", "Your studies", "Your photo"][step] }

    var body: some View {
        @Bindable var session = session
        let photo = session.draft.photo
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Step \(step + 1) of 3").font(.subheadline).foregroundStyle(.secondary)
                        ProgressView(value: Double(step + 1), total: 3).tint(Constants.Colors.orangeColor)
                        Text(title).font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                        Text(session.draftSaveError == nil ? "Your progress is saved on this device." : "Keep this screen open until your progress is saved.").font(.callout).foregroundStyle(.secondary)
                        if step < 2 { Text("All fields on this step are required.").font(.callout).foregroundStyle(.secondary) }
                    }
                    if step == 0 {
                        AuthField(title: "First name") { TextField("First name", text: $session.draft.firstName).textContentType(.givenName) }
                        AuthField(title: "Last name") { TextField("Last name", text: $session.draft.lastName).textContentType(.familyName) }
                        AuthField(title: "Birthdate") {
                            DatePicker("Birthdate", selection: $session.draft.birthdate, in: ...Date(), displayedComponents: .date)
                                .labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else if step == 1 {
                        AuthField(title: "Major") {
                            Button { choosingMajor = true } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(session.draft.major.isEmpty ? "Select your major" : session.draft.major)
                                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 12)
                                    Image(systemName: "chevron.down").font(.body)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }.foregroundStyle(.primary)
                        }
                        AuthField(title: "Graduation year") {
                            TextField("Graduation year", text: $session.draft.graduationYear).keyboardType(.numberPad)
                        }
                    } else {
                        Text("Choose a photo for your profile. You can also add one later.").foregroundStyle(.secondary)
                        Button { choosingPhoto = true } label: {
                            VStack(spacing: 16) {
                                if let data = photo, let image = UIImage(data: data) {
                                    Image(uiImage: image).resizable().scaledToFill()
                                        .frame(width: 160, height: 160).clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 100)).foregroundStyle(Color(uiColor: .secondaryLabel)).accessibilityHidden(true)
                                }
                                Text(photo == nil ? "Choose photo" : "Change photo").font(.headline)
                            }.frame(maxWidth: .infinity).padding(.vertical)
                        }
                        .disabled(saving)
                        .popover(isPresented: $choosingPhoto) {
                            OnboardingPhotoPicker(isPresented: $choosingPhoto) { result in
                                switch result {
                                case .success(let data): session.draft.photo = data; errorText = nil
                                case .failure: errorText = "Couldn’t prepare that photo. Please choose it again."
                                }
                            }
                            .frame(idealWidth: 500, idealHeight: 650)
                            .presentationCompactAdaptation(.fullScreenCover)
                            .ignoresSafeArea()
                        }
                        if session.draft.photo != nil {
                            Button("Remove photo", role: .destructive) { session.draft.photo = nil }
                        }
                    }
                    if let errorText { AuthError(message: errorText) }
                    if let message = session.draftSaveError {
                        AuthError(message: message)
                        Button("Retry saving progress") { session.persistDraft() }
                    }
                    if step == 2 {
                        Button(action: finish) {
                            HStack {
                                if saving { ProgressView().tint(.white) }
                                Text(saving ? "Saving profile…" : "Finish setup")
                            }
                        }.buttonStyle(AuthPrimaryButtonStyle()).disabled(saving)
                    } else {
                        Button("Continue") {
                            if let message = session.draft.validationMessage(for: step) { errorText = message }
                            else { session.draft.step = step + 1; errorText = nil }
                        }
                            .buttonStyle(AuthPrimaryButtonStyle())
                    }
                }.padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .disabled(saving)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step > 0 { Button("Back") { session.draft.step = step - 1; errorText = nil }.disabled(saving) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if session.accountInfo?.emailConfirmed == false {
                        Button("Verify email") { showingVerification = true }.disabled(saving)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } }
            }
        }
        .tint(AuthAppearance.tint)
        .sheet(isPresented: $showingVerification) {
            NavigationStack {
                VerifyEmailView()
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { showingVerification = false } } }
            }
        }
        .sheet(isPresented: $choosingMajor) {
            NavigationStack {
                List(Constants.Values.degrees.filter { majorSearch.isEmpty || $0.localizedCaseInsensitiveContains(majorSearch) }, id: \.self) { major in
                    Button {
                        session.draft.major = major
                        choosingMajor = false
                    } label: {
                        HStack {
                            Text(major).fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            if major == session.draft.major { Image(systemName: "checkmark").accessibilityLabel("Selected") }
                        }.foregroundStyle(.primary)
                    }
                }
                .searchable(text: $majorSearch, prompt: "Find your major")
                .navigationTitle("Major")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { choosingMajor = false } } }
            }.tint(AuthAppearance.tint)
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { session.persistDraft() }
            else { Task { do { try await session.refreshAccount() } catch { errorText = authenticationError(error) } } } }

    }

    private func finish() {
        guard !saving else { return }
        for index in 0...1 {
            if let message = session.draft.validationMessage(for: index) {
                session.draft.step = index; errorText = message; return
            }
        }
        saving = true
        errorText = nil
        Task {
            defer { saving = false }
            do { try await session.finishOnboarding() }
            catch { session.handle(error); errorText = authenticationError(error) }
        }
    }
}


// Keep selection and editing local. Only the confirmed crop replaces the saved draft;
// uploading remains part of Finish setup.
struct OnboardingPhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onResult: (Result<Data, Error>) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {
        context.coordinator.parent = self
    }
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    @MainActor
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: OnboardingPhotoPicker
        init(parent: OnboardingPhotoPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            do {
                guard let image = info[.editedImage] as? UIImage else { throw APIError.invalidResponse }
                parent.onResult(.success(try OnboardingPhotoPicker.jpegData(for: image)))
            } catch { parent.onResult(.failure(error)) }
            parent.isPresented = false
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }

    static func jpegData(for image: UIImage) throws -> Data {
        let size = image.size
        guard size.width > 0, size.height > 0 else { throw APIError.invalidResponse }
        let scale = min(1, 1600 / max(size.width, size.height))
        let outputSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let resized = UIGraphicsImageRenderer(size: outputSize, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: outputSize)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8), jpeg.count <= 5 * 1024 * 1024 else {
            throw APIError.invalidResponse
        }
        return jpeg
    }
}
