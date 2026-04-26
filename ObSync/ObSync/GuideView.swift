import SwiftUI

struct GuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        VaultSetupGuideView()
                    } label: {
                        Label("Setting up a vault", systemImage: "folder.badge.plus")
                    }
                    NavigationLink {
                        ShortcutSetupGuideView()
                    } label: {
                        Label("Setting up the shortcut", systemImage: "bolt")
                    }
                }

                Section {
                    Link(destination: URL(string: "https://github.com/KuSi833/ObSync/blob/master/GUIDE.md")!) {
                        HStack {
                            Label("Full guide on GitHub", systemImage: "book")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.firaCode(.caption))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                } footer: {
                    Text("More detailed instructions, troubleshooting, and tips.")
                        .font(.firaCode(.caption2))
                }
            }
            .navigationTitle("Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Vault Setup

private struct VaultSetupGuideView: View {
    var body: some View {
        List {
            Section {
                Text("ObSync syncs into a folder you've already set up as an Obsidian vault. Create the empty vault in Obsidian first, then point ObSync at it.")
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section("In Obsidian") {
                GuideStep(
                    number: 1,
                    title: "Create a new vault",
                    text: "Open Obsidian, tap 'Create new vault', name it, and turn 'Store in iCloud' off. Leave the vault empty."
                )
            }

            Section("In ObSync") {
                GuideStep(
                    number: 2,
                    title: "Add a vault",
                    text: "Tap + on the home screen and pick the GitHub repo you want to sync."
                )
                GuideStep(
                    number: 3,
                    title: "Pick the folder",
                    text: "In the folder picker, navigate to the Obsidian vault folder you just created and select it."
                )
                GuideStep(
                    number: 4,
                    title: "Sync",
                    text: "ObSync clones the repo into that folder. Open Obsidian and your notes will be there. Tap the sync button any time to pull updates."
                )
            }

            Section {
                NavigationLink {
                    ShortcutSetupGuideView()
                } label: {
                    Label("Set up the shortcut", systemImage: "bolt")
                }
            } header: {
                Text("Next")
            } footer: {
                Text("Trigger sync without opening the app.")
                    .font(.firaCode(.caption2))
            }
        }
        .navigationTitle("Vault Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shortcut Setup

private struct ShortcutSetupGuideView: View {
    var body: some View {
        List {
            Section {
                Text("Trigger sync without opening the app — from the Home Screen, Siri, automations, or focus modes.")
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section("Build the shortcut") {
                GuideStep(
                    number: 1,
                    title: "Open the Shortcuts app",
                    text: "Apple's built-in Shortcuts app — preinstalled on iOS."
                )
                GuideStep(
                    number: 2,
                    title: "Create a new shortcut",
                    text: "Tap + in the top right."
                )
                GuideStep(
                    number: 3,
                    title: "Add an ObSync action",
                    text: "Search 'ObSync' and pick 'Sync All Vaults', or 'Sync Vault' to target a specific one."
                )
                GuideStep(
                    number: 4,
                    title: "Name and save",
                    text: "Give the shortcut a name like 'Sync ObSync' and tap Done."
                )
            }

            Section("Run it") {
                GuideRow(
                    icon: "clock",
                    title: "Automate it",
                    text: "Set up a personal automation that runs your sync shortcut whenever Obsidian opens."
                )
                GuideRow(
                    icon: "mic",
                    title: "Hey Siri",
                    text: "Say the shortcut's name to run it."
                )
                GuideRow(
                    icon: "house",
                    title: "Add to Home Screen",
                    text: "From the shortcut's share menu, choose 'Add to Home Screen' for one-tap sync."
                )
            }
        }
        .navigationTitle("Shortcut Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Components

private struct GuideStep: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.firaCode(.headline))
                .bold()
                .foregroundStyle(.obsidianPurple)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.firaCode(.subheadline))
                    .bold()
                Text(text)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct GuideRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.firaCode(.headline))
                .foregroundStyle(.obsidianPurple)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.firaCode(.subheadline))
                    .bold()
                Text(text)
                    .font(.firaCode(.caption))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("Light") {
    GuideView()
}

#Preview("Dark") {
    GuideView()
        .preferredColorScheme(.dark)
}
