import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    @State private var oauthToken: String?
    @State private var vaultStore = VaultStore()

    var body: some View {
        if let token = oauthToken {
            VaultsListView(store: vaultStore, token: token) {
                oauthToken = nil
            }
            .task {
                vaultStore.preloadAllCommits()
                vaultStore.onTokenExpired = { oauthToken = nil }
            }
        } else {
            LoginView { token in
                oauthToken = token
            }
        }
    }

    private static let useFakeData = false // flip to true for screenshots

    init() {
        if Self.useFakeData {
            let store = VaultStore()
            var vault = Vault(repoFullName: "jules/vault", folderBookmark: Data(), folderName: "Vault", syncMode: .readWrite)
            vault.lastSynced = Date().addingTimeInterval(-120)
            store.vaults = [vault]
            store.recentCommits[vault.id] = [
                RecentCommit(id: "e83fa21", message: "Add weekly review template", date: Date().addingTimeInterval(-120)),
                RecentCommit(id: "b47cd09", message: "Updated reading list", date: Date().addingTimeInterval(-5400)),
                RecentCommit(id: "9f1a3e7", message: "New project kickoff notes", date: Date().addingTimeInterval(-14400)),
            ]
            _vaultStore = State(initialValue: store)
            _oauthToken = State(initialValue: "debug-token")
        } else {
            if let saved = GitHubAuth.loadToken() {
                _oauthToken = State(initialValue: saved)
            }
        }
    }
}

// MARK: - Folder Picker

struct FolderPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

#Preview {
    ContentView()
}
