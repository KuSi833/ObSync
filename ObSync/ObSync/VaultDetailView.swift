import SwiftUI

struct VaultDetailView: View {
    let vaultID: UUID
    @Bindable var store: VaultStore
    var token: String

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showFolderPicker = false
    @State private var showSyncModeInfo = false
    @State private var showConflictInfo = false
    @State private var branches: [GitHubAuth.Branch] = []
    @State private var showBranchPicker = false

    private var vault: Vault? {
        store.vaults.first { $0.id == vaultID }
    }

    private var status: SyncStatus {
        store.syncStatuses[vaultID] ?? .idle
    }

    var body: some View {
        if let vault {
            content(vault)
        }
    }

    private func content(_ vault: Vault) -> some View {
        List {
            Section {
                Button {
                    openOnGitHub(path: vault.repoFullName)
                } label: {
                    HStack {
                        Text(vault.repoFullName)
                            .font(.firaCode(.body))
                        Spacer()
                        Image("GitHubMark")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)

                Button {
                    showBranchPicker = true
                } label: {
                    HStack {
                        Text(vault.branch)
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
            } header: {
                Text("Repository")
            }

            Section("Folder") {
                if let name = vault.folderName {
                    Button(action: { showFolderPicker = true }) {
                        HStack {
                            Text(name)
                                .font(.firaCode(.body))
                            Spacer()
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                } else {
                    Button("Select Folder", action: { showFolderPicker = true })
                        .foregroundStyle(.red)
                }
            }

            Section {
                Toggle("Push local changes", isOn: Binding(
                    get: { vault.syncMode == .readWrite },
                    set: { store.updateSyncMode(for: vault.id, mode: $0 ? .readWrite : .readOnly) }
                ))
                .tint(.obsidianPurple)
            } header: {
                HStack {
                    Text("Sync Mode")
                    Spacer()
                    Button {
                        showSyncModeInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.firaCode(.footnote))
                            .foregroundStyle(.obsidianPurple)
                    }
                }
            }

            Section {
                switch status {
                case .idle:
                    if let date = vault.lastSynced {
                        LabeledContent("Last synced") {
                            Text(date.compactRelative)
                        }
                    } else {
                        Text("Never synced")
                            .foregroundStyle(.secondary)
                    }
                case .syncing:
                    AnimatedDotsText("Syncing")
                        .foregroundStyle(.secondary)
                case .cloning(let progress):
                    ProgressView(value: progress) {
                        Text("Cloning... \(Int(progress * 100))%")
                    }
                    .tint(.obsidianPurple)
                case .error(let message):
                    Text(message)
                        .foregroundStyle(.red)
                case .conflict(let files):
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("\(files.count) conflicting file\(files.count == 1 ? "" : "s")",
                                  systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Button { showConflictInfo = true } label: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.orange)
                            }
                        }
                        ForEach(files.prefix(5), id: \.self) { file in
                            Text(file)
                                .font(.firaCode(.caption))
                                .foregroundStyle(.secondary)
                        }
                        if files.count > 5 {
                            Text("and \(files.count - 5) more…")
                                .font(.firaCode(.caption))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Status")
            }

            if let commits = store.recentCommits[vault.id], !commits.isEmpty {
                Section {
                    ForEach(commits) { commit in
                        Button {
                            openOnGitHub(path: "\(vault.repoFullName)/commit/\(commit.id)")
                        } label: {
                            HStack {
                                Text(commit.message)
                                    .font(.firaCode(.caption))
                                    .lineLimit(1)
                                Spacer()
                                Text(commit.date.compactRelative)
                                    .font(.firaCode(.caption2))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.primary)
                    }
                } header: {
                    HStack {
                        Text("Recent Commits")
                        Spacer()
                        Button {
                            openOnGitHub(path: "\(vault.repoFullName)/commits/\(vault.branch)")
                        } label: {
                            Image(systemName: "arrow.up.right")
                                .font(.firaCode(.caption))
                                .foregroundStyle(.obsidianPurple)
                        }
                    }
                }
            }


        }
        .refreshable {
            store.loadRecentCommits(for: vault)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                if isConflict {
                    Button(action: { store.discardAndReset(vault: vault, token: token) }) {
                        Label("Discard", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .glassButton(tint: .red, glassTint: .red.opacity(0.3))

                    Button(action: { store.sync(vault: vault, token: token) }) {
                        Label("Retry", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .glassButton(tint: .obsidianPurple.opacity(0.3))
                } else {
                    Button(action: { store.sync(vault: vault, token: token) }) {
                        HStack {
                            Group {
                                if isSyncing {
                                    SpinningIcon(systemName: "arrow.triangle.2.circlepath")
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                            }
                            Text("Sync")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .glassButton(tint: .obsidianPurple.opacity(0.3))
                    .disabled(isSyncing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .task {
            branches = (try? await GitHubAuth.fetchBranches(repo: vault.repoFullName, token: token)) ?? []
        }
        .navigationTitle("Vault Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showBranchPicker) {
            NavigationStack {
                List(branches) { branch in
                    Button {
                        store.updateBranch(for: vault.id, branch: branch.name)
                        showBranchPicker = false
                    } label: {
                        HStack {
                            Text(branch.name)
                                .font(.firaCode(.body))
                            Spacer()
                            if branch.name == vault.branch {
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
        .sheet(isPresented: $showFolderPicker) {
            FolderPicker { url in
                guard url.startAccessingSecurityScopedResource() else { return }
                if let bookmark = try? url.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    store.updateFolder(for: vault.id, bookmark: bookmark)
                }
                url.stopAccessingSecurityScopedResource()
            }
        }
        .alert("Remove Vault?", isPresented: $showDeleteConfirm) {
            Button("Remove", role: .destructive) {
                store.delete(vault)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will stop syncing \(vault.repoFullName). Local files won't be deleted.")
        }
        .alert("Sync Mode", isPresented: $showSyncModeInfo) {
            Button("OK") {}
        } message: {
            Text("When off, ObSync only pulls the latest version from GitHub, discarding any local edits.\n\nWhen on, local changes are auto-committed and pushed before pulling. If both sides changed the same file, you'll be asked to resolve the conflict.")
        }
        .alert("Merge Conflict", isPresented: $showConflictInfo) {
            Button("OK") {}
        } message: {
            Text("Both you and the remote changed the same files. You can discard your local changes to accept the remote version, or use another app to resolve the merge conflict manually.")
        }
    }

    private var isSyncing: Bool {
        switch status {
        case .syncing, .cloning: true
        default: false
        }
    }

    private var isConflict: Bool {
        if case .conflict = status { return true }
        return false
    }

    private func openOnGitHub(path: String) {
        let githubApp = URL(string: "github://github.com/\(path)")!
        let safari = URL(string: "https://github.com/\(path)")!
        let app = UIApplication.shared
        if app.canOpenURL(githubApp) {
            app.open(githubApp)
        } else {
            app.open(safari)
        }
    }
}

#Preview("Idle - Never Synced") {
    let store = VaultStore()
    let vault = Vault(
        repoFullName: "kmilicic/obsidian-vault",
        folderBookmark: Data()
    )
    store.vaults = [vault]

    return NavigationStack {
        VaultDetailView(vaultID: vault.id, store: store, token: "fake-token")
    }
}

#Preview("Idle - Last Synced (with folder)") {
    let store = VaultStore()
    let bookmark = try! URL.documentsDirectory.bookmarkData()
    var vault = Vault(
        repoFullName: "kmilicic/obsidian-vault",
        folderBookmark: bookmark,
        folderName: "Documents"
    )
    vault.lastSynced = Date().addingTimeInterval(-3600)
    store.vaults = [vault]
    store.recentCommits[vault.id] = [
        RecentCommit(id: "abc123", message: "ObSync: 2026-04-11 14:30", date: Date().addingTimeInterval(-3600)),
        RecentCommit(id: "def456", message: "Updated daily note", date: Date().addingTimeInterval(-7200)),
        RecentCommit(id: "ghi789", message: "ObSync: 2026-04-10 09:15", date: Date().addingTimeInterval(-86400)),
    ]

    return NavigationStack {
        VaultDetailView(vaultID: vault.id, store: store, token: "fake-token")
    }
}

#Preview("Syncing") {
    let store = VaultStore()
    let vault = Vault(
        repoFullName: "kmilicic/obsidian-vault",
        folderBookmark: Data()
    )
    store.vaults = [vault]
    store.syncStatuses[vault.id] = .syncing

    return NavigationStack {
        VaultDetailView(vaultID: vault.id, store: store, token: "fake-token")
    }
}

#Preview("Cloning") {
    let store = VaultStore()
    let vault = Vault(
        repoFullName: "kmilicic/obsidian-vault",
        folderBookmark: Data()
    )
    store.vaults = [vault]
    store.syncStatuses[vault.id] = .cloning(progress: 0.42)

    return NavigationStack {
        VaultDetailView(vaultID: vault.id, store: store, token: "fake-token")
    }
}

#Preview("Error") {
    let store = VaultStore()
    let vault = Vault(
        repoFullName: "kmilicic/obsidian-vault",
        folderBookmark: Data()
    )
    store.vaults = [vault]
    store.syncStatuses[vault.id] = .error("Authentication failed: token expired")

    return NavigationStack {
        VaultDetailView(vaultID: vault.id, store: store, token: "fake-token")
    }
}

#Preview("Conflict") {
    let store = VaultStore()
    var vault = Vault(
        repoFullName: "kmilicic/obsidian-vault",
        folderBookmark: Data(),
        syncMode: .readWrite
    )
    vault.lastSynced = Date().addingTimeInterval(-600)
    store.vaults = [vault]
    store.syncStatuses[vault.id] = .conflict(["Daily Notes/2026-04-09.md", "Projects/todo.md"])

    return NavigationStack {
        VaultDetailView(vaultID: vault.id, store: store, token: "fake-token")
    }
}
