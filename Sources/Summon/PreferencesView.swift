import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var appState:      SummonAppState
    @EnvironmentObject var updateChecker: UpdateChecker

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }
                .environmentObject(appState)

            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
                .environmentObject(appState)
                .environmentObject(updateChecker)
        }
        .frame(width: 480, height: 300)
        .padding()
    }
}

// MARK: - General

private struct GeneralTab: View {
    @EnvironmentObject var appState: SummonAppState

    var body: some View {
        Form {
            Section("Expansion") {
                Toggle("Enable Summon", isOn: Binding(
                    get: { appState.isEnabled },
                    set: { appState.setEnabled($0) }
                ))
                .help("Pause or resume system-wide text expansion without quitting.")

                Toggle("Require word boundary before trigger", isOn: Binding(
                    get: { appState.requireWordBoundary },
                    set: { appState.setWordBoundary($0) }
                ))
                .help("When on, a trigger only fires after a space, newline, or punctuation — not in the middle of a word.")
            }

            Section("Accessibility") {
                HStack {
                    Image(systemName: appState.accessibilityGranted
                          ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(appState.accessibilityGranted ? .green : .orange)
                    Text(appState.accessibilityGranted
                         ? "Accessibility permission granted"
                         : "Accessibility permission required")
                    Spacer()
                    if !appState.accessibilityGranted {
                        Button("Grant…") {
                            appState.requestAccessibility()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { appState.refreshAccessibility() }
    }
}

// MARK: - About

private struct AboutTab: View {
    @EnvironmentObject var appState:      SummonAppState
    @EnvironmentObject var updateChecker: UpdateChecker

    var body: some View {
        VStack(spacing: 16) {
            // Update banner
            if let info = updateChecker.updateInfo {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Summon \(info.tagName) is available")
                    Spacer()
                    Button("Download") {
                        updateChecker.openReleasePage()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(10)
                .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            HStack(alignment: .top, spacing: 20) {
                Image(systemName: "s.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Summon").font(.title2.bold())
                    Text("Version \(AppVersion.current) (Build \(AppVersion.build))")
                        .foregroundStyle(.secondary)
                    Text("Free, local-first text expander for macOS.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Link("github.com/lswingrover/summon",
                         destination: URL(string: "https://github.com/lswingrover/summon")!)
                        .font(.callout)
                }
                Spacer()
            }

            HStack {
                Button("Check for Updates") {
                    updateChecker.checkInBackground()
                }
                Spacer()
                Text(updateChecker.updateInfo == nil
                     ? "Summon \(AppVersion.current) is up to date."
                     : "Update available!")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding()
    }
}
