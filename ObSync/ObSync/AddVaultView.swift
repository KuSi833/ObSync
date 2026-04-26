import SwiftUI

struct AddVaultView: View {
    var token: String
    var onCreate: (Vault) -> Void

    @Environment(\.dismiss) private var dismiss

    @State var repos: [GitHubAuth.Repo] = []
    @State var selectedRepo: GitHubAuth.Repo?
    @State var selectedFolder: URL?
    @State var folderBookmark: Data?
    @State var isLoadingRepos = true
    @State private var showFolderPicker = false
    @State private var searchText = ""
    @State var showNonEmptyConfirm = false
    @State var selectedBranch: String?
    @State var branches: [GitHubAuth.Branch] = []
    @State private var showBranchPicker = false

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
            .task(id: selectedRepo?.id) {
                guard let repo = selectedRepo else {
                    branches = []
                    selectedBranch = nil
                    return
                }
                selectedBranch = repo.default_branch
                branches = (try? await GitHubAuth.fetchBranches(repo: repo.full_name, token: token)) ?? []
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
        List {
            Section("Repository") {
                HStack {
                    Text(selectedRepo?.full_name ?? "")
                        .font(.firaCode(.body))
                    Spacer()
                    Image("GitHubMark")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showBranchPicker = true
                } label: {
                    HStack {
                        Text(selectedBranch ?? selectedRepo?.default_branch ?? "")
                            .font(.firaCode(.body))
                        Spacer()
                        Image("GitBranch")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
            }

            Section("Folder") {
                HStack {
                    Text(selectedFolder?.lastPathComponent ?? "")
                        .font(.firaCode(.body))
                    Spacer()
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showBranchPicker) {
            NavigationStack {
                List(branches) { branch in
                    Button {
                        selectedBranch = branch.name
                        showBranchPicker = false
                    } label: {
                        HStack {
                            Text(branch.name)
                                .font(.firaCode(.body))
                            Spacer()
                            if branch.name == selectedBranch {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.obsidianPurple)
                            }
                        }
                    }
                    .tint(.primary)
                }
                .navigationTitle("Branch")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showBranchPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button(action: createVault) {
                    Label("Add Vault", systemImage: "externaldrive.badge.icloud")
                        .font(.firaCode(.headline))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .glassButton(tint: .obsidianPurple.opacity(0.3))

                Button("Back") { selectedFolder = nil; folderBookmark = nil }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private func createVault() {
        guard let repo = selectedRepo, let bookmark = folderBookmark else { return }
        let branch = selectedBranch ?? repo.default_branch
        let vault = Vault(repoFullName: repo.full_name, branch: branch, folderBookmark: bookmark, folderName: selectedFolder?.lastPathComponent)
        onCreate(vault)
        dismiss()
    }
}

// MARK: - Previews

private let sampleRepos: [GitHubAuth.Repo] = [
    GitHubAuth.Repo(id: 1, full_name: "kmilicic/obsidian-vault", private: true, default_branch: "main"),
    GitHubAuth.Repo(id: 2, full_name: "kmilicic/second-brain", private: false, default_branch: "main"),
    GitHubAuth.Repo(id: 3, full_name: "kmilicic/work-notes", private: true, default_branch: "master"),
    GitHubAuth.Repo(id: 4, full_name: "kmilicic/journal", private: true, default_branch: "main"),
    GitHubAuth.Repo(id: 5, full_name: "kmilicic/recipes", private: false, default_branch: "main"),
]

#Preview("1. Loading Repos") {
    AddVaultView(
        token: "fake",
        onCreate: { _ in },
        isLoadingRepos: true
    )
}

#Preview("2. Repo Picker") {
    AddVaultView(
        token: "fake",
        onCreate: { _ in },
        repos: sampleRepos,
        isLoadingRepos: false
    )
}

#Preview("3. Folder Picker") {
    AddVaultView(
        token: "fake",
        onCreate: { _ in },
        repos: sampleRepos,
        selectedRepo: sampleRepos[0],
        isLoadingRepos: false
    )
}

private let sampleBranches: [GitHubAuth.Branch] = [
    GitHubAuth.Branch(name: "main"),
    GitHubAuth.Branch(name: "develop"),
    GitHubAuth.Branch(name: "feature/refactor-sync"),
    GitHubAuth.Branch(name: "release/v1.1"),
]

#Preview("4. Confirm — Light") {
    AddVaultView(
        token: "fake",
        onCreate: { _ in },
        repos: sampleRepos,
        selectedRepo: sampleRepos[0],
        selectedFolder: URL(fileURLWithPath: "/private/var/mobile/Containers/Shared/AppGroup/Obsidian/MyVault"),
        folderBookmark: Data(),
        isLoadingRepos: false,
        selectedBranch: "main",
        branches: sampleBranches
    )
}

#Preview("4. Confirm — Dark") {
    AddVaultView(
        token: "fake",
        onCreate: { _ in },
        repos: sampleRepos,
        selectedRepo: sampleRepos[0],
        selectedFolder: URL(fileURLWithPath: "/private/var/mobile/Containers/Shared/AppGroup/Obsidian/MyVault"),
        folderBookmark: Data(),
        isLoadingRepos: false,
        selectedBranch: "main",
        branches: sampleBranches
    )
    .preferredColorScheme(.dark)
}

#Preview("5. Non-empty Folder Alert") {
    AddVaultView(
        token: "fake",
        onCreate: { _ in },
        repos: sampleRepos,
        selectedRepo: sampleRepos[0],
        selectedFolder: URL(fileURLWithPath: "/private/var/mobile/Containers/Shared/AppGroup/Obsidian/MyVault"),
        folderBookmark: Data(),
        isLoadingRepos: false,
        showNonEmptyConfirm: true,
        selectedBranch: "main",
        branches: sampleBranches
    )
}
