import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLicenses = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                        Text("ObSync")
                            .font(.firaCode(.title2))
                            .bold()
                        Text("I've been an avid Obsidian user for a long time, and I just got tired of the existing options for syncing my git-hosted vault to my phone. So I built my own.")
                            .font(.firaCode(.subheadline))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text("Hope you find it useful.")
                            .font(.firaCode(.subheadline))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }

                Section {
                    Link(destination: URL(string: "https://github.com/KuSi833/ObSync")!) {
                        HStack {
                            Label("Support ObSync", systemImage: "heart")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }

                Section {
                    Link(destination: URL(string: "https://gist.github.com/KuSi833/cd91eddcc91e090880c1b56cc0eb8bc1")!) {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)

                    Button {
                        showLicenses = true
                    } label: {
                        HStack {
                            Label("Open Source Licenses", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.firaCode(.caption))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showLicenses) {
                LicensesView()
            }
        }
    }
}

// MARK: - Licenses

struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("SwiftGitX") {
                    Text(swiftGitXLicense)
                        .font(.firaCode(.caption2))
                }

                Section("libgit2") {
                    Text(libgit2License)
                        .font(.firaCode(.caption2))
                }
            }
            .navigationTitle("Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private let swiftGitXLicense = """
    MIT License

    Copyright (c) 2024 Ibrahim Cetin

    Permission is hereby granted, free of charge, to any person obtaining a copy \
    of this software and associated documentation files (the "Software"), to deal \
    in the Software without restriction, including without limitation the rights \
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
    copies of the Software, and to permit persons to whom the Software is \
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all \
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
    SOFTWARE.
    """

    private let libgit2License = """
    libgit2 is Copyright (C) the libgit2 contributors, unless otherwise stated. \
    See the AUTHORS file for details.

    Note that the only valid version of the GPL as far as this project is concerned \
    is _this_ particular version of the license (ie v2, not v2.2 or v3.x or whatever), \
    as this is the only version of the GPL that has been approved for use with libgit2.

    This program is free software; you can redistribute it and/or modify it under \
    the terms of the GNU General Public License, version 2, as published by the \
    Free Software Foundation.

    In addition to the permissions in the GNU General Public License, the authors \
    give you unlimited permission to link the compiled version of this library into \
    combinations with other programs, and to distribute those combinations without \
    any restriction coming from the use of this file. (The General Public License \
    restrictions do apply in other respects; for example, they cover modification \
    of the file, and distribution when not linked into a combined executable.)

    This program is distributed in the hope that it will be useful, but WITHOUT ANY \
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A \
    PARTICULAR PURPOSE. See the GNU General Public License for more details.
    """
}

#Preview {
    AboutView()
}
