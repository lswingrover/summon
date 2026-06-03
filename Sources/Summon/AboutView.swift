import SwiftUI

struct AboutView: View {
    @EnvironmentObject var updateChecker: UpdateChecker

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "s.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Summon")
                .font(.title.bold())

            Text("Version \(AppVersion.current)")
                .foregroundStyle(.secondary)

            Divider()

            if let info = updateChecker.updateInfo {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(.blue)
                    Text("Version \(info.tagName) is available")
                    Button("Download") { updateChecker.openReleasePage() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            } else {
                Text("Free, local-first text expander for macOS.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Link("github.com/lswingrover/summon",
                 destination: URL(string: "https://github.com/lswingrover/summon")!)
                .font(.caption)
        }
        .padding(28)
        .frame(width: 300)
    }
}
