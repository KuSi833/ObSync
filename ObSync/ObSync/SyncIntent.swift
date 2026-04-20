import AppIntents
import SwiftGitX

// MARK: - Vault as App Entity

struct VaultEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Vault")
    static var defaultQuery = VaultEntityQuery()

    var id: UUID
    var repoFullName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(repoFullName)")
    }
}

struct VaultEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [VaultEntity] {
        let store = VaultStore()
        return store.vaults
            .filter { identifiers.contains($0.id) }
            .map { VaultEntity(id: $0.id, repoFullName: $0.repoFullName) }
    }

    func suggestedEntities() async throws -> [VaultEntity] {
        let store = VaultStore()
        return store.vaults.map { VaultEntity(id: $0.id, repoFullName: $0.repoFullName) }
    }
}

// MARK: - Shared Sync Logic

enum VaultSync {
    static func sync(_ vault: Vault, token: String) async throws {
        guard let repoURL = GitHubAuth.authenticatedURL(repo: vault.repoFullName, token: token) else {
            throw SyncError.invalidURL
        }

        guard let folder = vault.resolveFolder() else {
            throw SyncError.folderAccess
        }

        let accessing = folder.startAccessingSecurityScopedResource()
        defer { if accessing { folder.stopAccessingSecurityScopedResource() } }

        let gitDir = folder.appendingPathComponent(".git")

        if FileManager.default.fileExists(atPath: gitDir.path) {
            let repo = try Repository.open(at: folder)
            try await repo.fetch()
            let currentBranch = try repo.branch.current
            if let upstream = currentBranch.upstream,
               let remoteCommit = upstream.target as? Commit {
                try repo.reset(to: remoteCommit, mode: .hard)
            }
        } else {
            _ = try await Repository.clone(from: repoURL, to: folder)
        }
    }
}

private enum SyncError: LocalizedError {
    case invalidURL
    case folderAccess

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid repo URL"
        case .folderAccess: "Can't access folder"
        }
    }
}

// MARK: - Sync Single Vault Intent

struct SyncVaultIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync Vault"
    static var description = IntentDescription("Syncs a specific ObSync vault via git")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Vault")
    var vault: VaultEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let token = GitHubAuth.loadToken() else {
            return .result(dialog: "Not logged in to GitHub")
        }

        let store = VaultStore()

        guard let vaultData = store.vaults.first(where: { $0.id == vault.id }) else {
            return .result(dialog: "Vault not found")
        }

        do {
            try await VaultSync.sync(vaultData, token: token)
            store.updateLastSynced(for: vaultData.id)
            return .result(dialog: "Synced \(vaultData.repoFullName)")
        } catch {
            return .result(dialog: "Failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Sync All Vaults Intent

struct SyncAllVaultsIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync All Vaults"
    static var description = IntentDescription("Syncs all ObSync vaults via git")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let token = GitHubAuth.loadToken() else {
            return .result(dialog: "Not logged in to GitHub")
        }

        let store = VaultStore()

        guard !store.vaults.isEmpty else {
            return .result(dialog: "No vaults configured")
        }

        var synced = 0
        var errors: [String] = []

        for vault in store.vaults {
            do {
                try await VaultSync.sync(vault, token: token)
                store.updateLastSynced(for: vault.id)
                synced += 1
            } catch {
                errors.append("\(vault.repoFullName): \(error.localizedDescription)")
            }
        }

        if errors.isEmpty {
            return .result(dialog: "Synced \(synced) vault\(synced == 1 ? "" : "s")")
        } else {
            return .result(dialog: "Synced \(synced), failed \(errors.count): \(errors.joined(separator: "; "))")
        }
    }
}

// MARK: - Suggested Shortcuts

struct ObSyncShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SyncAllVaultsIntent(),
            phrases: [
                "Sync my vaults with \(.applicationName)",
                "Sync \(.applicationName)",
            ],
            shortTitle: "Sync All Vaults",
            systemImageName: "arrow.triangle.2.circlepath"
        )
    }
}
