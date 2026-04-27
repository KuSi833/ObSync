<p align="center">
  <img src="assets/logo with background.png" width="128" height="128" alt="ObSync logo">
</p>

<h1 align="center">ObSync</h1>

<p align="center">
  A native iOS app for syncing your Obsidian vaults via git.
  <br>
  Fast, simple, no fuss.
</p>

<p align="center">
  <a href="https://apps.apple.com/gb/app/obsync/id6762672240">
    <img src="assets/app-store-badge.svg" alt="Download on the App Store" height="48">
  </a>
</p>

<p align="center">
  <img src="assets/screenshots/Simulator Screenshot - iPhone 17 Pro Max - 2026-04-25 at 00.44.47.png" width="240" alt="Login screen">
  <img src="assets/screenshots/Simulator Screenshot - iPhone 17 Pro Max - 2026-04-25 at 00.44.34.png" width="240" alt="Vault list">
  <img src="assets/screenshots/Simulator Screenshot - iPhone 17 Pro Max - 2026-04-25 at 00.44.38.png" width="240" alt="Vault details">
</p>

## What is this?

ObSync syncs your git-hosted Obsidian vault to your iPhone or iPad. One tap to pull the latest, or let it push your changes too. No terminal, no workarounds, no emulators.

For a walkthrough of how I actually use ObSync day-to-day (silent sync on Obsidian launch, editing remotely with Claude Code), see [GUIDE.md](GUIDE.md).

## Features

- **One-tap sync**, clone on first run, fetch + reset on subsequent syncs
- **Read-only or read-write**, pull only, or auto-commit and push local changes
- **Multi-vault**, sync as many repos as you want
- **Branch selection**, pick which branch to track per vault
- **Shortcuts & Siri**, sync vaults from the home screen or by voice
- **Conflict detection**, warns you when local and remote diverge, with a one-tap discard option
- **GitHub OAuth**, secure login, token stored in iOS Keychain

## Privacy

**ObSync does not collect, store, or share any user data.**

- No analytics, no tracking, no crash reporting
- Your GitHub token lives only in the iOS Keychain on your device
- Vault config and folder bookmarks stay local
- Network traffic goes to GitHub's API only

Full details in [PRIVACY.md](PRIVACY.md).

## Requirements

- iOS 17+
- A GitHub account with at least one repository

## How It Works

**Read-only mode:** `git fetch` + `git reset --hard` to the remote HEAD. Your phone always has the latest version, local edits are discarded.

**Read-write mode:** Stage all changes, auto-commit with a timestamp, fetch, check for divergence, and push. If both sides changed the same files, you get a conflict warning with the option to discard local changes.

## How is this different from...

- **github-gitless-sync** (Obsidian plugin): Uses the GitHub REST API, so files over ~25 MB break and big vaults sync slowly. ObSync uses real git, no size cap, single packfile transfer.
- **Working Copy**: Generic git client, paid Obsidian unlock, and (in my experience, maybe fixed since) the cross-app folder access tends to go stale on iOS. ObSync is purpose-built for vaults and owns the full pipeline.
- **Obsidian Sync**: Official and polished, but paid and capped (1 GB / 5 MB per file on Standard). ObSync is free and uses your GitHub repo.
- **Syncthing / iCloud / OneDrive**: File sync with no version history. ObSync gives you real git commits and rollback.

## Tech Stack

Built with SwiftUI and [SwiftGitX](https://github.com/ibrahimcetin/SwiftGitX) (libgit2). GitHub OAuth for auth; tokens in iOS Keychain, vault config in UserDefaults, folder access via security-scoped bookmarks.

## Support

If you find ObSync useful, it helps keep development going.

<a href="https://buymeacoffee.com/kmilicic"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Found a bug or have a feature request? [Open an issue](https://github.com/KuSi833/ObSync/issues).

## License

ObSync is released under the [MIT License](LICENSE).

It builds on these open source libraries:

- **SwiftGitX**, MIT License
- **libgit2**, GPLv2 with linking exception
