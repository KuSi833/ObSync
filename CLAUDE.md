# ObSync — iOS Git Sync for Obsidian

Native iOS app that syncs Obsidian vaults via git. Read-only sync model: fetch + hard reset (discard local, pull latest from remote).

## Stack

- **SwiftUI** — all UI
- **libgit2** via [SwiftGitX](https://github.com/ibrahimcetin/SwiftGitX) 0.4.0 — native git operations (clone, fetch, reset)
- **GitHub OAuth Device Flow** — authentication, token stored in iOS Keychain

## Key Docs

- `docs/PLAN.md` — architecture, decisions, POC status, future plans
- `docs/UX.md` — screen-by-screen UX spec with data model

## Project Layout

```
ObSync/ObSync/
├── ObSyncApp.swift        — app entry point
├── ContentView.swift      — main UI + sync logic
├── GitHubAuth.swift       — OAuth device flow + GitHub API
├── Vault.swift            — Vault data model + VaultStore persistence/sync
├── VaultsListView.swift   — home screen (list of vaults)
├── VaultDetailView.swift  — single vault detail/sync/remove
├── AddVaultView.swift     — add vault flow (pick repo → pick folder → confirm)
├── LoginView.swift        — login screen
└── Theme.swift            — shared styling
```

## Core Concepts

- **Vault** = a remote GitHub repo synced to a local folder on device
- Sync is one-tap: clone on first run, fetch + hard reset on subsequent runs
- Multi-vault support from the start
- `syncMode` field exists for future read-write support
- Destructive actions use "Remove" (not "Delete") to signal it only unlinks, doesn't touch remote/local files

## Build

Open `ObSync/ObSync.xcodeproj` in Xcode. SwiftGitX is added via SPM.
