import SwiftUI

struct AddVaultView: View {
    var token: String
    var onCreate: (Vault) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var repos: [GitHubAuth.Repo] = []
    @State private var selectedRepo: GitHubAuth.Repo?
    @State private var selectedFolder: URL?
    @State private var folderBookmark: Data?
    @State private var isLoadingRepos = true
    @State private var showFolderPicker = false
    @State private var searchText = ""
    @State private var showNonEmptyConfirm = false

    private var filteredRepos: [GitHubAuth.Repo] {
        if searchText.isEmpty { return repos }
        return repos.filter { $0.full_name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedRepo == nil {
                    repoPickerStep
                } else if selectedFolder == nil {
                    folderPickerStep
                } else {
                    confirmStep
                }
            }
            .navigationTitle("Add Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                do {
                    repos = try await GitHubAuth.fetchRepos(token: token)
                } catch {}
                isLoadingRepos = false
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPicker { url in
                    guard url.startAccessingSecurityScopedResource() else {
                        selectedFolder = url
                        return
                    }
                    if let bookmark = try? url.bookmarkData(
                        options: .minimalBookmark,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        folderBookmark = bookmark
                    }
                    url.stopAccessingSecurityScopedResource()
                    selectedFolder = url

                    // Check if folder is non-empty
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path),
                       !contents.isEmpty {
                        showNonEmptyConfirm = true
                    }
                }
            }
            .alert("Folder is not empty", isPresented: $showNonEmptyConfirm) {
                Button("Replace Contents", role: .destructive) {
                    // Proceed — folder will be cleared before clone
                }
                Button("Choose Different Folder", role: .cancel) {
                    selectedFolder = nil
                    folderBookmark = nil
                }
            } message: {
                Text("All existing files in this folder will be replaced with the repository contents.")
            }
        }
    }

    // MARK: - Step 1: Pick Repo

    private var repoPickerStep: some View {
        Group {
            if isLoadingRepos {
                ProgressView("Loading repos...")
                    .frame(maxHeight: .infinity)
            } else {
                List(filteredRepos) { repo in
                    Button {
                        selectedRepo = repo
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(repo.full_name)
                                    .font(.firaCode(.body))
                                if repo.private {
                                    Text("Private")
                                        .font(.firaCode(.caption))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search repos")
            }
        }
    }

    // MARK: - Step 2: Pick Folder

    private var folderPickerStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text(selectedRepo?.full_name ?? "")
                    .font(.firaCode(.headline))
                Text("Choose a local folder for this vault")
                    .font(.firaCode(.subheadline))
                    .foregroundStyle(.secondary)
            }

            Button(action: { showFolderPicker = true }) {
                Label("Select Folder", systemImage: "folder")
                    .font(.firaCode(.headline))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .glassButton()

            Button("Back") { selectedRepo = nil }
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Step 3: Confirm

    private var confirmStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Repository")
                        .font(.firaCode(.caption))
                        .foregroundStyle(.secondary)
                    Text(selectedRepo?.full_name ?? "")
                        .font(.firaCode(.body))
                        .bold()
                }

                VStack(spacing: 4) {
                    Text("Folder")
                        .font(.firaCode(.caption))
                        .foregroundStyle(.secondary)
                    Text(selectedFolder?.lastPathComponent ?? "")
                        .font(.firaCode(.body))
                        .bold()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)

            Button(action: createVault) {
                Label("Add Vault", systemImage: "externaldrive.badge.icloud")
                    .font(.firaCode(.headline))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .glassButton()

            Button("Back") { selectedFolder = nil; folderBookmark = nil }
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func createVault() {
        guard let repo = selectedRepo, let bookmark = folderBookmark else { return }
        let vault = Vault(repoFullName: repo.full_name, branch: repo.default_branch, folderBookmark: bookmark, folderName: selectedFolder?.lastPathComponent)
        onCreate(vault)
        dismiss()
    }
}
