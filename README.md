# Summon

A native macOS text expander — free, local-first, and fully headless-ready. Type a short trigger anywhere; Summon replaces it with the full expansion instantly, in every app.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

```
;addr  →  123 Main Street, Post Falls, ID 83854
;sig   →  Best,\nLouis Swingrover
;meet  →  Grab a slot: https://cal.com/me
;ty    →  Thanks so much — really appreciate it!
```

---

## Why this exists

TextExpander is the category leader, but it costs $40/year, requires a cloud account, and phones home constantly. Espanso is open source but config-file-driven — no GUI. Alfred has snippet support buried inside a broader launcher. None of them offer programmatic access that lets an AI agent read and write your snippet library on your behalf.

Summon fills a specific gap: a native macOS text expander that is completely free, stores everything locally in SQLite, and exposes 100% of its functionality through a local HTTP API — meaning Claude or any other AI can manage your snippet library without you touching the UI.

**Typical use cases:**
- You have a set of email fragments, addresses, signatures, and boilerplate you type dozens of times a day and want a single keystroke to insert them
- You want to tell Claude "add a snippet for my work email" and have it work immediately
- You want your snippet library accessible from scripts, automations, or other tools via a clean REST API
- You want a TextExpander replacement that will never ask you for a credit card

---


**How Summon compares to the field:**

| | TextExpander | Espanso | Alfred Snippets | Raycast Snippets | Summon |
|---|---|---|---|---|---|
| **Price** | $40/year | Free | Requires Alfred ($35 Powerpack) | Pro subscription | Free |
| **GUI** | Yes | No (YAML config files) | Basic | Good | Yes (native SwiftUI) |
| **Companion API** | No | No | No | No | Yes -- full REST at localhost:14732 |
| **AI management** | No | No | No | Via Raycast AI | Yes -- Claude reads and writes library |
| **Dynamic content** | Date/time/fill-in/scripts | Yes (scripts, shell, regex) | Date/time | Date/time/clipboard | Planned (Phase 2) |
| **Fill-in fields** | Yes | Yes | No | No | Planned (Phase 2) |
| **Cloud sync** | Yes (required) | No | No | Yes (required for team) | No (local SQLite, by design) |
| **Cross-platform** | Mac + Windows + iOS | Mac + Windows + Linux | Mac only | Mac only | Mac only (intentionally) |
| **Open source** | No | Yes (MIT) | No | No | Yes (MIT) |
| **System-wide** | Yes | Yes | Yes | Yes | Yes (CGEventTap) |

TextExpander is the category standard and it's worth paying for if you use fill-in fields or team sharing heavily. For individual Mac users who just want a text expander that works, is free, and lets Claude manage their snippet library, the subscription overhead doesn't make sense.

The Espanso gap: Espanso is more powerful (regex matching, shell scripts, multi-step expansions), but the YAML-file workflow means maintaining your snippet library feels like maintaining config files. There is no GUI. There is no way to tell Claude "add a snippet for X" and have it work immediately.

## Features

### System-wide expansion
Summon installs a `CGEventTap` at the `cgSessionEventTap` level, which intercepts keyboard events before they reach any application. This means expansion works in every app on your Mac — browsers, editors, email clients, Slack, Terminal, notes apps, everything — without any per-app configuration.

When you type a trigger followed by a word boundary (space, punctuation, newline), Summon fires: it sends backspace keystrokes to erase the trigger, writes the expansion to your pasteboard, sends ⌘V to paste, then silently restores your original pasteboard contents. The whole sequence takes under 200ms and is imperceptible.

### Menu bar + full snippet manager
Summon lives in your menu bar with no Dock icon. Left-click the **S** icon to open the snippet manager window; right-click for a quick menu with About and Quit.

The snippet manager is a full-width `NavigationSplitView`: a searchable list on the left, a detail pane on the right showing the full expansion with one-click editing. Add, edit, delete, and enable/disable snippets without leaving the window. The editor sheet has a multi-line expansion field, an optional label for organization, and an enabled toggle.

### Per-snippet enable/disable
Each snippet has an `enabled` flag. Disabled snippets stay in your library and appear in the manager (dimmed), but the expansion engine skips them. Useful for snippets you use seasonally or want to keep for reference without triggering.

### Local SQLite storage
All snippets are stored in `~/Library/Application Support/Summon/summon.db`. No cloud, no account, no telemetry. The database is a single SQLite file you can back up, copy between machines, or inspect with any SQLite browser.

The schema is intentionally simple: one `snippets` table with `id` (UUID), `trigger` (unique), `expansion`, `label`, `enabled`, `created_at`, and `updated_at`. Migrations run automatically at launch.

### Companion API (port 14732)
Every action available in the UI is reachable programmatically via a local HTTP server on port 14732. The API accepts and returns JSON:

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness check — returns version |
| `GET` | `/snippets` | All snippets |
| `POST` | `/snippets` | Create a snippet `{trigger, expansion, label?}` |
| `DELETE` | `/snippets/:id` | Delete by UUID |

This is what powers the Claude companion plugin — and what makes Summon scriptable from the terminal, Shortcuts, or any HTTP client.

### Claude companion plugin
Install `companion-plugin/summon-companion.plugin` in Claude → Settings → Capabilities → Customize → Add Plugin. Three skills are included:

| Skill | What it does |
|-------|-------------|
| `summon-list` | Lists all your snippets in a table |
| `summon-add` | Adds a new snippet — describe it in plain English |
| `summon-search` | Finds snippets by keyword across trigger, expansion, and label |

Example: *"Add a snippet — trigger `;meet`, expansion 'Grab a slot: https://cal.com/me'"* → Summon adds it immediately.

---

## Install

> **This repo contains source code only — there is no pre-built binary.** You build it yourself in about 60 seconds using the script below. The script handles compilation, app bundle assembly, ad-hoc signing, and installation to `/Applications`.

### Prerequisites

- **macOS 14 Sonoma or later**
- **Xcode Command Line Tools** (free, ~2 GB). If you don't have them:
  ```bash
  xcode-select --install
  ```
  A dialog will appear — click **Install** and wait. Skip if you already have Xcode installed.

You do **not** need a paid Apple Developer account. You do **not** need the full Xcode app.

### Build & install

```bash
git clone https://github.com/lswingrover/summon ~/Developer/summon
cd ~/Developer/summon
bash build_app.sh
```

The script compiles the Swift source in release mode, assembles `Summon.app`, ad-hoc signs it, installs it to `/Applications`, and registers it with LaunchServices. Total time: ~60 seconds on Apple Silicon.

### First launch — Gatekeeper warning

Because Summon is ad-hoc signed (not notarized by Apple), macOS blocks the first launch with:

> *"Summon cannot be opened because it is from an unidentified developer."*

**Fix — Option A (GUI):** In Finder, navigate to `/Applications`, right-click `Summon.app` → **Open** → click **Open** in the confirmation dialog. You only need to do this once.

**Fix — Option B (Terminal):**
```bash
xattr -dr com.apple.quarantine /Applications/Summon.app
open /Applications/Summon.app
```

> **Why is it safe?** The ad-hoc signature proves the binary hasn't been tampered with since it was compiled on your machine. It just lacks Apple's notarization stamp, which is only required for distributing software to other machines.

### First launch — grant Accessibility permission

Summon intercepts keystrokes using macOS Accessibility APIs. On first launch, a dialog appears:

> *"Summon needs Accessibility access to detect your trigger shortcuts."*

Click **Open System Settings**, find Summon in the Accessibility list, and toggle it on. Expansion will silently fail until this is granted. You can also navigate there manually: **System Settings → Privacy & Security → Accessibility**.

### Updating

```bash
cd ~/Developer/summon
git pull
bash build_app.sh
```

The script replaces the existing `/Applications/Summon.app` automatically.

---

## Usage

Summon lives entirely in your menu bar — no Dock icon, no app switcher entry.

**Add a snippet:**
1. Click the **S** icon in the menu bar
2. Click **+** (Add Snippet) in the toolbar
3. Enter a **trigger** (e.g. `;addr`) and the full **expansion** text
4. Optionally add a **label** (e.g. "Home address") for organization
5. Click **Add Snippet**

**Use a snippet:**
Type the trigger anywhere, then press Space, Return, or any punctuation. Summon replaces it instantly.

**Trigger conventions:**
- Prefix triggers with `;` or `!` to avoid accidental matches — `;email` is much safer than `email`
- Short prefixes expand fast; longer ones give more control
- Triggers are case-sensitive: `;Hi` and `;hi` are different triggers

**Edit or delete:**
Open the snippet manager, select a snippet, click **Edit** in the detail pane — or right-click a row for the context menu.

**Disable without deleting:**
Open the editor for a snippet and toggle **Enabled** off. The snippet stays in your library but won't expand until you re-enable it.

---

## Architecture

```
Sources/
├── SummonCore/                    Pure Swift — no AppKit, fully unit-testable
│   ├── Snippet.swift              Model: id, trigger, expansion, label, enabled, timestamps
│   ├── DatabaseManager.swift      SQLite CRUD via libsqlite3 — schema init, migrations
│   ├── SnippetStore.swift         Actor wrapping DatabaseManager — thread-safe state
│   ├── TriggerMatcher.swift       Rolling typed-character buffer; detects trigger matches
│   ├── KeyboardMonitor.swift      CGEventTap install/teardown; routes chars + backspace
│   └── ExpansionInjector.swift    Backspace N times → pasteboard write → ⌘V → restore
└── Summon/                        AppKit/SwiftUI app target
    ├── SummonApp.swift            @main + AppDelegate — wires pipeline, starts server
    ├── SnippetManagerView.swift   NavigationSplitView — searchable list + detail pane
    ├── SnippetEditorView.swift    Add/edit sheet — trigger, expansion, label, enabled
    ├── CompanionServer.swift      NWListener HTTP server on port 14732
    ├── AppVersion.swift           Version string — kept in sync by ship_summon.py
    └── AboutView.swift
Tests/
└── SummonTests/
    ├── DatabaseManagerTests.swift  7 tests: schema, CRUD, duplicate trigger, ordering
    └── TriggerMatcherTests.swift   9 tests: match at buffer start, after space/newline,
                                    no match mid-word, backspace, isExpanding guard, reset
build_app.sh                        Build (release) + bundle + ad-hoc sign + /Applications install
ship_summon.py                      Ship: version bump + build + git tag + GitHub release
Info.plist                          Bundle metadata — LSUIElement=true, accessibility description
companion-plugin/                   Claude Cowork plugin
    plugin.json
    skills/summon-list/SKILL.md
    skills/summon-add/SKILL.md
    skills/summon-search/SKILL.md
```

**Expansion pipeline:**

```
KeyboardMonitor (CGEventTap)
    │
    ├─ char → TriggerMatcher.process()
    │              │
    │              └─ match found → ExpansionInjector.inject()
    │                                   │
    │                                   ├─ send N backspaces (erase trigger)
    │                                   ├─ write expansion to NSPasteboard
    │                                   ├─ send ⌘V
    │                                   └─ restore original pasteboard
    └─ backspace → TriggerMatcher.handleBackspace()
```

---

## Design decisions

**Why `CGEventTap` instead of `AXObserver` or an Input Method Extension?**

`AXObserver` monitors text field state changes via the Accessibility API — it's app-specific, fragile across app updates, and doesn't work in many contexts (browsers, Electron apps, terminals). An Input Method Extension is the most reliable approach but requires a separate app extension bundle, Apple review for distribution, and significant complexity for what is ultimately a simple use case.

`CGEventTap` at `cgSessionEventTap` intercepts keyboard events at the session level, before any app sees them. This is exactly how TextExpander and Espanso work. It requires Accessibility permission — which Summon already needs — and works in every app without per-app configuration.

**Why pasteboard injection instead of synthesized keystroke-per-character?**

Synthesizing one `CGEvent` per character works but is slow for long expansions (a 500-character expansion generates 1000+ events). It also breaks in apps that interpret individual keystroke events differently than pasted text (some rich-text editors, IDEs with autocomplete).

Pasteboard injection is the standard approach: write the expansion to `NSPasteboard`, send ⌘V, restore the original pasteboard contents. It's instant regardless of expansion length, behaves identically to a manual paste, and works correctly in every app that supports paste — which is all of them.

**Why a `TriggerMatcher` rolling buffer instead of monitoring `AXValue` of the focused element?**

Reading `AXValue` (the text content of a focused field) is slow (~5ms round trip), fires a permission prompt in some app contexts, and requires knowing which field is focused at all times. The rolling buffer approach is simpler: maintain a fixed-size buffer of the last N characters typed, check for trigger suffix matches after every keystroke. Buffer reset on match or on non-printable keys keeps state clean. The whole match check runs in microseconds.

**Why `SummonCore` as a separate SPM target?**

The expansion engine — `DatabaseManager`, `SnippetStore`, `TriggerMatcher`, `ExpansionInjector` — has no AppKit dependency. Separating it into `SummonCore` means tests can run against the full business logic without launching the app or requiring Accessibility permission. This is the same pattern used by GridForge (`GridForgeCore`) and is the reason the test suite runs cleanly in CI.

**Why raw `libsqlite3` instead of CoreData or GRDB?**

CoreData's managed object model adds boilerplate and doesn't compose well with Swift's value types. GRDB is excellent but adds a dependency. Summon's schema is a single table with seven columns. The raw SQLite wrapper (`DatabaseManager.swift`) is ~150 lines, fully explicit, and has no magic. The migration path is a schema version check at init — straightforward to extend as the schema grows.

**Why ad-hoc signing instead of Developer ID?**

Summon is a personal tool built for local use. Apple's notarization requirement applies to apps distributed to other machines. Ad-hoc signing (`codesign --sign -`) satisfies Gatekeeper's tamper-detection requirement for local builds without a paid developer account. If you want to distribute it, swap `--sign -` for `--sign "Developer ID Application: <you>"` and add `xcrun notarytool` to the build script.

---

## Requirements

- macOS 14 Sonoma or later
- Xcode Command Line Tools (for building from source)
- Accessibility permission (prompted on first launch; required for system-wide expansion)

---

## Roadmap

| Issue | Feature |
|-------|---------|
| [#1](https://github.com/lswingrover/summon/issues/1) | Build + install via `build_app.sh` |
| [#2](https://github.com/lswingrover/summon/issues/2) | App icon (`summon.icns`) |
| [#3](https://github.com/lswingrover/summon/issues/3) | iCloud sync — share snippet library across Macs |
| [#4](https://github.com/lswingrover/summon/issues/4) | Import from TextExpander (`.snippets` bundle format) |
| [#5](https://github.com/lswingrover/summon/issues/5) | `scotty:summon-companion-ship` — companion plugin ship skill |

---

## Related tools

These apps are built by the same author and follow the same install pattern — build from source, no App Store, optional Claude companion plugin:

| App | What it does |
|-----|-------------|
| [ClipWatch](https://github.com/lswingrover/ClipWatch) | Clipboard history manager — searchable, sensitive clip detection, Touch ID, hotkey panel |
| [MacWatch](https://github.com/lswingrover/MacWatch) | System health monitor — CPU thermals, memory pressure, battery health, process anomalies |
| [NetWatch](https://github.com/lswingrover/NetWatch) | Network monitor — ping, DNS, Wi-Fi metrics, automatic incident bundling, ISP escalation drafts |
| [GridForge](https://github.com/lswingrover/gridforge) | Window layout manager — grid overlay, named layouts, per-app snap rules, layout snapshots |

---

## License

MIT — see [LICENSE](LICENSE).
