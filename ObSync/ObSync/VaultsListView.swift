import SwiftUI

struct VaultsListView: View {
    @Bindable var store: VaultStore
    var token: String
    var onLogout: () -> Void

    @State private var showAddVault = false
    @State private var vaultToDelete: Vault?
    @State private var showIdentityEditor = false
    @State private var showAbout = false
    @State private var username: String?

    var body: some View {
        NavigationStack {
            Group {
                if store.vaults.isEmpty {
                    emptyState
                } else {
                    vaultsList
                }
            }
            .navigationTitle("ObSync")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddVault = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Label(username ?? "Account", systemImage: "person.crop.circle")
                            .disabled(true)
                        Button("Git Identity", systemImage: "person.text.rectangle") {
                            showIdentityEditor = true
                        }
                        Button("About", systemImage: "info.circle") {
                            showAbout = true
                        }
                        Button("Log out", role: .destructive, action: logout)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                username = try? await GitHubAuth.fetchUser(token: token).login
            }
            .sheet(isPresented: $showAddVault) {
                AddVaultView(token: token) { newVault in
                    store.add(newVault)
                    store.sync(vault: newVault, token: token)
                }
            }
            .sheet(isPresented: $showIdentityEditor) {
                GitIdentityEditorView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("Remove Vault?", isPresented: .init(
                get: { vaultToDelete != nil },
                set: { if !$0 { vaultToDelete = nil } }
            )) {
                Button("Remove", role: .destructive) {
                    if let vault = vaultToDelete {
                        store.delete(vault)
                    }
                    vaultToDelete = nil
                }
                Button("Cancel", role: .cancel) { vaultToDelete = nil }
            } message: {
                if let vault = vaultToDelete {
                    Text("This will stop syncing \(vault.repoFullName). Local files won't be deleted.")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            Text("No vaults yet")
                .font(.firaCode(.headline))
                .foregroundStyle(.secondary)
            Button("Add Vault") { showAddVault = true }
                .font(.firaCode(.headline))
                .glassButton()
        }
    }

    // MARK: - Vaults List

    private var vaultsList: some View {
        List {
            ForEach(store.vaults) { vault in
                NavigationLink(destination: VaultDetailView(vaultID: vault.id, store: store, token: token)) {
                    VaultCardView(vault: vault, status: store.syncStatuses[vault.id] ?? .idle, lastCommitMessage: store.recentCommits[vault.id]?.first?.message) {
                        store.sync(vault: vault, token: token)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Remove", role: .destructive) {
                        vaultToDelete = vault
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private func logout() {
        GitHubAuth.deleteToken()
        store.clear()
        onLogout()
    }
}

#Preview("Empty State") {
    VaultsListView(store: VaultStore(), token: "fake-token", onLogout: {})
}

#Preview("With Vaults") {
    let store = VaultStore()
    var v1 = Vault(repoFullName: "kmilicic/obsidian-vault", folderBookmark: Data())
    v1.lastSynced = Date().addingTimeInterval(-300)
    var v2 = Vault(repoFullName: "kmilicic/second-brain", folderBookmark: Data())
    v2.lastSynced = Date().addingTimeInterval(-86400)
    let v3 = Vault(repoFullName: "kmilicic/work-notes", folderBookmark: Data())
    store.vaults = [v1, v2, v3]
    store.syncStatuses[v2.id] = .syncing
    store.syncStatuses[v3.id] = .error("Can't access folder")

    return VaultsListView(store: store, token: "fake-token", onLogout: {})
}

// MARK: - Vault Card

struct VaultCardView: View {
    let vault: Vault
    let status: SyncStatus
    var lastCommitMessage: String?
    let onSync: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vault.repoFullName)
                    .font(.firaCode(.body))
                    .bold()
                    .lineLimit(1)

                statusView
            }

            Spacer()

            Button(action: onSync) {
                Group {
                    if isSyncing {
                        SpinningIcon(systemName: "arrow.triangle.2.circlepath")
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                .font(.firaCode(.title3))
            }
            .glassButton(tint: .obsidianPurple.opacity(0.3))
            .disabled(isSyncing)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .idle:
            if let date = vault.lastSynced {
                HStack(spacing: 4) {
                    Text(date.compactRelative)
                    if let msg = lastCommitMessage {
                        Text("·")
                        Text(msg)
                            .lineLimit(1)
                    }
                }
                .font(.firaCode(.caption))
                .foregroundStyle(.secondary)
            } else {
                Text("Never synced")
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
            }
        case .syncing:
            AnimatedDotsText("Syncing")
                .font(.firaCode(.caption))
                .foregroundStyle(.secondary)
        case .cloning(let progress):
            ProgressView(value: progress) {
                Text("\(Int(progress * 100))%")
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
            }
        case .error(let message):
            Text(message)
                .font(.firaCode(.caption))
                .foregroundStyle(.red)
                .lineLimit(1)
        case .conflict:
            Label("Conflict", systemImage: "exclamationmark.triangle.fill")
                .font(.firaCode(.caption))
                .foregroundStyle(.orange)
        }
    }

    private var isSyncing: Bool {
        switch status {
        case .syncing, .cloning: true
        default: false
        }
    }
}

#Preview("Card - Synced") {
    var vault = Vault(repoFullName: "kmilicic/obsidian-vault", folderBookmark: Data())
    vault.lastSynced = Date().addingTimeInterval(-600)
    return VaultCardView(vault: vault, status: .idle, onSync: {})
        .padding()
}

#Preview("Card - Syncing") {
    VaultCardView(
        vault: Vault(repoFullName: "kmilicic/obsidian-vault", folderBookmark: Data()),
        status: .syncing,
        onSync: {}
    )
    .padding()
}

#Preview("Card - Error") {
    VaultCardView(
        vault: Vault(repoFullName: "kmilicic/obsidian-vault", folderBookmark: Data()),
        status: .error("Can't access folder"),
        onSync: {}
    )
    .padding()
}
