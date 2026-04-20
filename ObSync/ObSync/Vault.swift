import Foundation
import os
import SwiftGitX

private nonisolated(unsafe) let logger = Logger(subsystem: "com.obsync", category: "sync")

enum SyncMode: String, Codable {
    case readOnly
    case readWrite
}

struct RecentCommit: Identifiable {
    let id: String  // full hash
    let message: String
    let date: Date
}

enum SyncStatus: Equatable {
    case idle
    case syncing
    case cloning(progress: Double)
    case error(String)
    case conflict([String])
}

struct Vault: Identifiable, Codable {
    let id: UUID
    var repoFullName: String
    var branch: String
    var folderBookmark: Data
    var folderName: String?
    var syncMode: SyncMode
    var lastSynced: Date?

    init(repoFullName: String, branch: String = "main", folderBookmark: Data, folderName: String? = nil, syncMode: SyncMode = .readOnly) {
        self.id = UUID()
        self.repoFullName = repoFullName
        self.branch = branch
        self.folderBookmark = folderBookmark
        self.folderName = folderName
        self.syncMode = syncMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        repoFullName = try container.decode(String.self, forKey: .repoFullName)
        branch = try container.decodeIfPresent(String.self, forKey: .branch) ?? "main"
        folderBookmark = try container.decode(Data.self, forKey: .folderBookmark)
        folderName = try container.decodeIfPresent(String.self, forKey: .folderName)
        syncMode = try container.decode(SyncMode.self, forKey: .syncMode)
        lastSynced = try container.decodeIfPresent(Date.self, forKey: .lastSynced)
    }

    func resolveFolder() -> URL? {
        var isStale = false
        return try? URL(resolvingBookmarkData: folderBookmark, bookmarkDataIsStale: &isStale)
    }
}

// MARK: - Persistence

@Observable
class VaultStore {
    private static let key = "savedVaults"

    var vaults: [Vault] = []
    var syncStatuses: [UUID: SyncStatus] = [:]
    var recentCommits: [UUID: [RecentCommit]] = [:]
    var onTokenExpired: (() -> Void)?

    init() {
        load()
    }

    func add(_ vault: Vault) {
        vaults.append(vault)
        save()
    }

    func delete(_ vault: Vault) {
        vaults.removeAll { $0.id == vault.id }
        syncStatuses.removeValue(forKey: vault.id)
        save()
    }

    func clear() {
        vaults.removeAll()
        syncStatuses.removeAll()
        recentCommits.removeAll()
        save()
    }

    func updateFolder(for vaultID: UUID, bookmark: Data) {
        if let index = vaults.firstIndex(where: { $0.id == vaultID }) {
            vaults[index].folderBookmark = bookmark
            var isStale = false
            vaults[index].folderName = (try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale))?.lastPathComponent
            save()
        }
    }

    func updateSyncMode(for vaultID: UUID, mode: SyncMode) {
        if let index = vaults.firstIndex(where: { $0.id == vaultID }) {
            vaults[index].syncMode = mode
            save()
        }
    }

    func updateBranch(for vaultID: UUID, branch: String) {
        if let index = vaults.firstIndex(where: { $0.id == vaultID }) {
            vaults[index].branch = branch
            save()
        }
    }

    func updateLastSynced(for vaultID: UUID) {
        if let index = vaults.firstIndex(where: { $0.id == vaultID }) {
            vaults[index].lastSynced = Date()
            save()
        }
    }

    func preloadAllCommits() {
        for vault in vaults {
            loadRecentCommits(for: vault)
        }
    }

    func loadRecentCommits(for vault: Vault) {
        let vaultID = vault.id
        let repoName = vault.repoFullName
        guard let folder = vault.resolveFolder() else { return }

        Task.detached { [self] in
            let accessing = folder.startAccessingSecurityScopedResource()
            defer { if accessing { folder.stopAccessingSecurityScopedResource() } }

            do {
                let repo = try Repository.open(at: folder)
                let entries = try repo.log().prefix(3).map { commit in
                    RecentCommit(
                        id: commit.id.hex,
                        message: commit.summary,
                        date: commit.date
                    )
                }
                let result = Array(entries)
                logger.info("Loaded \(result.count) recent commits for \(repoName)")
                await MainActor.run { recentCommits[vaultID] = result }
            } catch {
                logger.error("Failed to read git log for \(repoName): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sync

    func sync(vault: Vault, token: String) {
        guard let repoURL = GitHubAuth.authenticatedURL(repo: vault.repoFullName, token: token) else {
            logger.error("Invalid repo URL for \(vault.repoFullName)")
            syncStatuses[vault.id] = .error("Invalid repo URL")
            return
        }

        guard let folder = vault.resolveFolder() else {
            logger.error("Can't resolve folder for \(vault.repoFullName)")
            syncStatuses[vault.id] = .error("Can't access folder")
            return
        }

        logger.info("Starting sync for \(vault.repoFullName) [\(vault.syncMode.rawValue)]")
        syncStatuses[vault.id] = .syncing

        Task.detached { [self] in
            let accessing = folder.startAccessingSecurityScopedResource()
            defer { if accessing { folder.stopAccessingSecurityScopedResource() } }

            let gitDir = folder.appendingPathComponent(".git")
            let isExistingRepo = FileManager.default.fileExists(atPath: gitDir.path)

            do {
                if isExistingRepo {
                    logger.info("Opening existing repo at \(folder.path)")
                    let repo = try Repository.open(at: folder)

                    // Update remote URL with current token
                    try repo.config.set("remote.origin.url", to: repoURL.absoluteString)

                    // Set git user from saved identity
                    if let identity = GitIdentity.current {
                        try repo.config.set("user.name", to: identity.name)
                        try repo.config.set("user.email", to: identity.email)
                    }

                    // Switch branch if needed
                    let currentBranchName = (try? repo.branch.current.name) ?? ""
                    if currentBranchName != vault.branch {
                        logger.info("Switching from \(currentBranchName) to \(vault.branch)")
                        if let localBranch = try? repo.branch.get(named: vault.branch, type: .local) {
                            try repo.switch(to: localBranch)
                        } else if let remoteBranch = try? repo.branch.get(named: "origin/\(vault.branch)", type: .remote) {
                            try repo.switch(to: remoteBranch)
                        }
                    }

                    switch vault.syncMode {
                    case .readOnly:
                        logger.info("Fetching (read-only)...")
                        try await repo.fetch()
                        let currentBranch = try repo.branch.current
                        if let upstream = currentBranch.upstream,
                           let remoteCommit = upstream.target as? Commit {
                            logger.info("Resetting to remote commit \(remoteCommit.id.hex.prefix(7))")
                            try repo.reset(to: remoteCommit, mode: .hard)
                        }

                    case .readWrite:
                        // Stage all changed files
                        let statusEntries = try repo.status()
                        let changedPaths = statusEntries.compactMap { entry -> String? in
                            entry.workingTree?.newFile.path ?? entry.workingTree?.oldFile.path
                        }
                        logger.info("Found \(changedPaths.count) changed files")

                        if !changedPaths.isEmpty {
                            for path in changedPaths {
                                logger.debug("Staging: \(path)")
                                try repo.add(path: path)
                            }

                            // Auto-commit
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd HH:mm"
                            let message = "ObSync: \(formatter.string(from: Date()))"
                            logger.info("Committing: \(message)")
                            try repo.commit(message: message)
                        }

                        // Fetch and check for divergence
                        logger.info("Fetching (read-write)...")
                        try await repo.fetch()
                        let currentBranch = try repo.branch.current
                        if let upstream = currentBranch.upstream,
                           let remoteCommit = upstream.target as? Commit {
                            let localCommit = currentBranch.target as? Commit
                            logger.info("Local: \(localCommit?.id.hex.prefix(7) ?? "nil"), Remote: \(remoteCommit.id.hex.prefix(7))")

                            // Check if we've diverged (remote has commits we don't have)
                            let remoteIsAncestor = localCommit.map { local in
                                (try? repo.log(from: local).contains(where: { $0.id == remoteCommit.id })) ?? false
                            } ?? false

                            if !remoteIsAncestor && localCommit?.id != remoteCommit.id, let localCommit {
                                // Diverged — check which files differ
                                logger.warning("Divergence detected")
                                let diff = try repo.diff(from: localCommit, to: remoteCommit)
                                let conflictFiles = diff.changes.map(\.newFile.path)
                                logger.warning("Conflicting files: \(conflictFiles.joined(separator: ", "))")
                                await MainActor.run { syncStatuses[vault.id] = .conflict(conflictFiles) }
                                return
                            }
                        }

                        // Push
                        logger.info("Pushing...")
                        try await repo.push()
                    }
                } else {
                    // Clear folder contents before cloning (libgit2 requires empty directory)
                    let fm = FileManager.default
                    if let contents = try? fm.contentsOfDirectory(atPath: folder.path) {
                        for item in contents {
                            try? fm.removeItem(atPath: folder.appendingPathComponent(item).path)
                        }
                    }

                    logger.info("Cloning \(vault.repoFullName) to \(folder.path)")
                    await MainActor.run { syncStatuses[vault.id] = .cloning(progress: 0) }
                    _ = try await Repository.clone(from: repoURL, to: folder) { progress in
                        let total = progress.totalObjects
                        let received = progress.receivedObjects
                        if total > 0 {
                            Task { @MainActor in
                                self.syncStatuses[vault.id] = .cloning(progress: Double(received) / Double(total))
                            }
                        }
                    }
                }

                await MainActor.run {
                    loadRecentCommits(for: vault)
                    syncStatuses[vault.id] = .idle
                    updateLastSynced(for: vault.id)
                }
                logger.info("Sync complete for \(vault.repoFullName)")
            } catch let error as SwiftGitXError where error.code == .auth {
                logger.error("Auth error during sync for \(vault.repoFullName): \(error.message)")
                await MainActor.run {
                    syncStatuses[vault.id] = .error("Session expired")
                    GitHubAuth.deleteToken()
                    onTokenExpired?()
                }
            } catch let error as SwiftGitXError {
                logger.error("SwiftGitX error [\(String(describing: error.code))] [\(String(describing: error.category))]: \(error.message)")
                await MainActor.run { syncStatuses[vault.id] = .error(error.message) }
            } catch {
                logger.error("Sync error: \(error.localizedDescription)")
                await MainActor.run { syncStatuses[vault.id] = .error(error.localizedDescription) }
            }
        }
    }

    /// Abort merge and reset to remote (used when user chooses "Discard my changes" on conflict)
    func discardAndReset(vault: Vault, token: String) {
        guard let folder = vault.resolveFolder() else {
            logger.error("Can't resolve folder for discard+reset on \(vault.repoFullName)")
            syncStatuses[vault.id] = .error("Can't access folder")
            return
        }

        logger.info("Discarding local changes for \(vault.repoFullName)")
        syncStatuses[vault.id] = .syncing

        Task.detached { [self] in
            let accessing = folder.startAccessingSecurityScopedResource()
            defer { if accessing { folder.stopAccessingSecurityScopedResource() } }

            do {
                let repo = try Repository.open(at: folder)
                let currentBranch = try repo.branch.current
                if let upstream = currentBranch.upstream,
                   let remoteCommit = upstream.target as? Commit {
                    logger.info("Resetting to remote \(remoteCommit.id.hex.prefix(7))")
                    try repo.reset(to: remoteCommit, mode: .hard)
                }
                logger.info("Discard+reset complete for \(vault.repoFullName)")
                await MainActor.run {
                    syncStatuses[vault.id] = .idle
                    updateLastSynced(for: vault.id)
                }
            } catch let error as SwiftGitXError {
                logger.error("Discard+reset SwiftGitX error [\(String(describing: error.code))] [\(String(describing: error.category))]: \(error.message)")
                await MainActor.run { syncStatuses[vault.id] = .error(error.message) }
            } catch {
                logger.error("Discard+reset error: \(error.localizedDescription)")
                await MainActor.run { syncStatuses[vault.id] = .error(error.localizedDescription) }
            }
        }
    }

    // MARK: - Storage

    private func save() {
        if let data = try? JSONEncoder().encode(vaults) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([Vault].self, from: data) else { return }
        vaults = decoded
    }
}
