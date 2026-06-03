import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState:      SummonAppState
    @EnvironmentObject var updateChecker: UpdateChecker
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        // ── Update banner ────────────────────────────────────────────────────
        if let info = updateChecker.updateInfo {
            Button("✨ Summon \(info.tagName) available…") {
                updateChecker.openReleasePage()
            }
            Divider()
        }

        // ── Enable / disable ─────────────────────────────────────────────────
        Toggle(isOn: Binding(
            get: { appState.isEnabled },
            set: { appState.setEnabled($0) }
        )) {
            Text(appState.isEnabled ? "Summon is On" : "Summon is Off")
        }

        Divider()

        // ── Accessibility warning ─────────────────────────────────────────────
        if !appState.accessibilityGranted {
            Button("⚠️ Grant Accessibility Access…") {
                appState.requestAccessibility()
            }
            Divider()
        }

        // ── Snippets ──────────────────────────────────────────────────────────
        Button("Open Snippet Manager\(appState.snippetCount > 0 ? "  (\(appState.snippetCount))" : "")") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "snippets")
        }

        Divider()

        // ── App ───────────────────────────────────────────────────────────────
        Button("Preferences…") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "prefs")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("About Summon…") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "about")
        }

        Divider()

        Button("Quit Summon") {
            NSApplication.shared.terminate(nil)
        }
    }
}
