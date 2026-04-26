# How I Use ObSync

A personal writeup of my flow. The in-app guide covers the basics. This one explains how I actually use it.

## My Setup

I use ObSync read-only. I don't edit notes on my phone, the editing UX just isn't great. Instead, I run Claude Code on a remote machine, and it edits, commits, and pushes my notes to GitHub.

An iOS automation runs an ObSync sync every time I open Obsidian, so the app always opens to fresh notes. I never tap sync, and I never deal with conflicts.

The loop:

1. Claude Code edits notes remotely → pushes to GitHub
2. I open Obsidian → automation pulls latest → read

If you also do your real editing elsewhere (desktop, remote, whatever), this setup might suit you. If you edit on your phone, use the read-write toggle instead. This guide isn't for that flow.

## 1. Create the Obsidian vault

Open Obsidian, tap **Create new vault**, name it, and turn **Store in iCloud** off. Leave it empty. The folder ends up in Files → *On My iPhone → Obsidian*.

## 2. Add the vault in ObSync

Tap **+**, pick your repo, and select the empty Obsidian folder. ObSync clones into it. Open Obsidian and your notes are there.

Default mode is read-only: every sync is a fetch + hard reset. That's what I want.

## 3. Build the sync shortcut

In Shortcuts, create a new shortcut and add the **Sync All Vaults** action (or **Sync Vault** for a specific one). Name it something short.

In its settings, turn **Show When Run** off, otherwise the Shortcuts UI flashes on every sync.

## 4. Automate it on Obsidian launch

Switch to the **Automation** tab → **+** → **Personal Automation** → **App** → pick **Obsidian** → **Is Opened**. Add a **Run Shortcut** action pointing at the sync shortcut. Turn **Notify When Run** off.

Now opening Obsidian syncs first, silently. By the time I see the file list, it's current.

## 5. Editing remotely with Claude Code

I keep a Claude Code session running on a remote machine with the notes repo cloned there. When I want to write or restructure something, I tell Claude Code what to do. It edits, commits, and pushes.

How you reach Claude Code remotely is up to you (SSH, tmux, hosted, whatever). The point is any tool that edits the repo and pushes works. Claude Code is just what I use.
