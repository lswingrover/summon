import AppKit
import Foundation
import UserNotifications

// MARK: - Model

struct UpdateInfo: Equatable {
    let tagName:    String
    let releaseURL: URL
}

// MARK: - UpdateChecker

/// Fires once per launch. Polls the GitHub releases API, compares semver to
/// the running version, and posts a UNUserNotification + publishes updateInfo
/// so MenuBarView and PreferencesView can surface a banner.
@MainActor
final class UpdateChecker: ObservableObject {
    @Published var updateInfo: UpdateInfo?

    private let repoAPI: URL =
        URL(string: "https://api.github.com/repos/lswingrover/summon/releases/latest")
        ?? URL(string: "https://api.github.com")!

    private let releasesPage: URL =
        URL(string: "https://github.com/lswingrover/summon/releases")
        ?? URL(string: "https://github.com")!

    private var alreadyChecked = false

    // MARK: - Public

    func checkInBackground() {
        guard !alreadyChecked else { return }
        alreadyChecked = true
        Task.detached(priority: .background) { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            await self?.fetch()
        }
    }

    func openReleasePage() {
        NSWorkspace.shared.open(releasesPage)
    }

    func currentVersion() -> String { AppVersion.current }

    // MARK: - Private

    private func fetch() async {
        var req = URLRequest(url: repoAPI)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 10
        guard
            let (data, _) = try? await URLSession.shared.data(for: req),
            let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rawTag    = json["tag_name"] as? String
        else { return }

        let tag     = rawTag.hasPrefix("v") ? String(rawTag.dropFirst()) : rawTag
        let htmlURL = (json["html_url"] as? String).flatMap(URL.init(string:)) ?? releasesPage

        guard isNewer(tag, thanCurrent: currentVersion()) else { return }

        let info = UpdateInfo(tagName: tag, releaseURL: htmlURL)
        updateInfo = info
        await fireNotification(version: tag)
    }

    private func fireNotification(version: String) async {
        let content       = UNMutableNotificationContent()
        content.title     = "Summon \(version) available"
        content.body      = "A new version is ready. Open Summon to view the update."
        content.sound     = .default
        let request = UNNotificationRequest(
            identifier: "com.lswingrover.summon.update.\(version)",
            content:    content,
            trigger:    nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Semver

    private func isNewer(_ candidate: String, thanCurrent current: String) -> Bool {
        let cv = parts(current)
        let nv = parts(candidate)
        for i in 0 ..< max(cv.count, nv.count) {
            let c = i < cv.count ? cv[i] : 0
            let n = i < nv.count ? nv[i] : 0
            if n > c { return true }
            if n < c { return false }
        }
        return false
    }

    private func parts(_ v: String) -> [Int] {
        v.split(separator: ".").compactMap { Int($0) }
    }
}
