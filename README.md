<p align="center">
  <img src="assets/logo with background.png" width="128" height="128" alt="ObSync logo">
</p>

<h1 align="center">ObSync</h1>

<p align="center">
  A native iOS app for syncing your Obsidian vaults via git.
  <br>
  Fast, simple, no fuss.
</p>

## What is this?

ObSync syncs your git-hosted Obsidian vault to your iPhone or iPad. One tap to pull the latest, or let it push your changes too. No terminal, no workarounds, no emulators.

Built with SwiftUI and [libgit2](https://github.com/libgit2/libgit2) (via [SwiftGitX](https://github.com/ibrahimcetin/SwiftGitX)) for native git performance.

## Features

- **One-tap sync** -- clone on first run, fetch + reset on subsequent syncs
- **Read-only or read-write** -- pull only, or auto-commit and push local changes
- **Multi-vault** -- sync as many repos as you want
- **Branch selection** -- pick which branch to track per vault
- **Shortcuts & Siri** -- sync vaults from the home screen or by voice
- **Conflict detection** -- warns you when local and remote diverge, with a one-tap discard option
- **GitHub OAuth** -- secure login, token stored in iOS Keychain

## Requirements

- iOS 26+
- A GitHub account with at least one repository

## How It Works

**Read-only mode:** `git fetch` + `git reset --hard` to the remote HEAD. Your phone always has the latest version, local edits are discarded.

**Read-write mode:** Stage all changes, auto-commit with a timestamp, fetch, check for divergence, and push. If both sides changed the same files, you get a conflict warning with the option to discard local changes.

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI | SwiftUI |
| Git | libgit2 via [SwiftGitX](https://github.com/ibrahimcetin/SwiftGitX) |
| Auth | GitHub OAuth (redirect flow) |
| Storage | iOS Keychain (token), UserDefaults (vault config), Security-scoped bookmarks (folder access) |

## Support

If you find ObSync useful, it helps keep development going.

<a href="https://buymeacoffee.com/kmilicic"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Found a bug or have a feature request? [Open an issue](https://github.com/KuSi833/ObSync/issues).

## License

ObSync uses the following open source libraries:

- **SwiftGitX** -- MIT License
- **libgit2** -- GPLv2 with linking exception
