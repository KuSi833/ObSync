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
                            GitIdentity(name: name.trimmingCharacters(in: .whitespaces),
                                        email: email.trimmingCharacters(in: .whitespaces)).save()
                            onSave()
                        } label: {
                            Text("Save")
                                .font(.firaCode(.headline))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .glassButton()
                        .disabled(name.isEmpty || email.isEmpty)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
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
