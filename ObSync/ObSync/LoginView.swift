import SwiftUI

struct LoginView: View {
    var onLogin: (String) -> Void

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Branding
            VStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                Text("ObSync")
                    .font(.firaCode(.largeTitle))
                    .bold()
                Text("Sync Obsidian vaults via Git")
                    .font(.firaCode(.subheadline))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: login) {
                Label("Login with GitHub", systemImage: "person.circle")
                    .font(.firaCode(.headline))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.obsidianPurple)
            .disabled(isLoading)

            if let error = errorMessage {
                Text(error)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let token = try await GitHubAuth.authenticate()
                GitHubAuth.saveToken(token)
                onLogin(token)
            } catch GitHubAuth.AuthError.denied {
                // User cancelled — no error message needed
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview("Login") {
    LoginView(onLogin: { _ in })
}
