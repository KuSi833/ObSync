import SwiftUI

struct GitIdentity: Codable, Equatable {
    var name: String
    var email: String

    static var current: GitIdentity? {
        guard let data = UserDefaults.standard.data(forKey: "gitIdentity"),
              let identity = try? JSONDecoder().decode(GitIdentity.self, from: data) else { return nil }
        return identity
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "gitIdentity")
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: "gitIdentity")
    }
}

// MARK: - Shared Form

struct GitIdentityFormView: View {
    var dismissable: Bool
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State var name: String
    @State var email: String
    @State private var showInfo = false
    @State var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .font(.firaCode(.body))
                        .textContentType(.name)
                        .autocorrectionDisabled()

                    TextField("Email", text: $email)
                        .font(.firaCode(.body))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    HStack {
                        Text("Commit Author")
                        Spacer()
                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.firaCode(.footnote))
                                .foregroundStyle(.obsidianPurple)
                        }
                    }
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.firaCode(.caption))
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    HStack(spacing: 16) {
                        if dismissable {
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.firaCode(.headline))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .glassButton(tint: .gray, glassTint: .gray.opacity(0.65))
                        }

                        Button {
                            let trimmedName = name.trimmingCharacters(in: .whitespaces)
                            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                            if trimmedName.isEmpty && trimmedEmail.isEmpty {
                                errorMessage = "Name and email are required."
                            } else if trimmedName.isEmpty {
                                errorMessage = "Name is required."
                            } else if trimmedEmail.isEmpty {
                                errorMessage = "Email is required."
                            } else {
                                errorMessage = nil
                                GitIdentity(name: trimmedName, email: trimmedEmail).save()
                                onSave()
                            }
                        } label: {
                            Text("Save")
                                .font(.firaCode(.headline))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .glassButton()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Git Identity")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Git Identity", isPresented: $showInfo) {
                Button("OK") {}
            } message: {
                Text("This name and email will appear as the author on git commits made by ObSync.")
            }
        }
    }
}

// MARK: - Setup (first login)

struct GitIdentityView: View {
    var onComplete: () -> Void

    var body: some View {
        GitIdentityFormView(dismissable: false, onSave: onComplete, name: "", email: "")
    }
}

// MARK: - Editor (from menu)

struct GitIdentityEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GitIdentityFormView(
            dismissable: true,
            onSave: { dismiss() },
            name: GitIdentity.current?.name ?? "",
            email: GitIdentity.current?.email ?? ""
        )
    }
}

#Preview("Setup") {
    GitIdentityView(onComplete: {})
}

#Preview("Editor") {
    GitIdentityEditorView()
}

#Preview("Validation Error") {
    GitIdentityFormView(
        dismissable: true,
        onSave: {},
        name: "",
        email: "",
        errorMessage: "Name and email are required."
    )
}
