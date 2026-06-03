import AppKit
import SummonCore

/// Central shared state for Summon. Owns enable/disable, accessibility status,
/// and snippet count for menu bar display.
@MainActor
final class SummonAppState: ObservableObject {
    static let shared = SummonAppState()

    // MARK: - Published state

    @Published var isEnabled: Bool = {
        // Default true for new installs (UserDefaults.bool returns false when key absent)
        guard UserDefaults.standard.object(forKey: "summon.enabled") != nil else { return true }
        return UserDefaults.standard.bool(forKey: "summon.enabled")
    }()

    @Published var requireWordBoundary: Bool = {
        guard UserDefaults.standard.object(forKey: "summon.wordBoundary") != nil else { return true }
        return UserDefaults.standard.bool(forKey: "summon.wordBoundary")
    }()

    @Published var accessibilityGranted: Bool = false
    @Published var snippetCount: Int = 0

    // MARK: - Back-references (set by AppDelegate)

    weak var monitor: KeyboardMonitor?
    var store: SnippetStore?

    // MARK: - Init

    private init() {
        refreshAccessibility()
    }

    // MARK: - Actions

    func setEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: "summon.enabled")
        if value {
            guard KeyboardMonitor.isAccessibilityGranted() else { return }
            monitor?.start()
        } else {
            monitor?.stop()
        }
    }

    func setWordBoundary(_ value: Bool) {
        requireWordBoundary = value
        UserDefaults.standard.set(value, forKey: "summon.wordBoundary")
        // TriggerMatcher reads this flag at match time (wired via AppDelegate)
    }

    func refreshAccessibility() {
        accessibilityGranted = KeyboardMonitor.isAccessibilityGranted()
    }

    func refreshSnippetCount() {
        Task {
            let count = await store?.snippets.count ?? 0
            await MainActor.run { snippetCount = count }
        }
    }

    func requestAccessibility() {
        KeyboardMonitor.requestAccessibility()
        // Re-check after a short delay so status updates in UI
        Task {
            try? await Task.sleep(for: .seconds(1))
            refreshAccessibility()
        }
    }
}
