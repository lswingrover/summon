# Summon Roadmap

Summon is a native macOS text expander that stores snippets in local SQLite and exposes a companion API so Claude can read and write the snippet library. The core expansion engine and companion plugin are shipped. This document tracks what comes next.

---

## Phase 1: Core (Complete)

- System-wide CGEventTap expansion engine
- Trigger detection with word-boundary awareness
- SQLite storage with UUID primary keys and per-snippet enabled flag
- SwiftUI snippet manager (NavigationSplitView -- list + detail)
- Companion API at localhost:14732 (GET /snippets, POST /snippets, DELETE /:id)
- Claude companion plugin (summon-companion.plugin: summon-list, summon-add, summon-search)
- Menu bar app, no Dock icon

---

## Phase 2: Dynamic Expansions

**Goal:** Make expansions do more than paste static text.

- **Date/time tokens** -- `{date}` expands to today's date in configured format; `{time}` to current time; `{datetime}` to ISO 8601. Token syntax is configurable (braces vs. percent-style).
- **Clipboard token** -- `{clipboard}` inserts current clipboard content into the expansion. Useful for wrappers: `;url` expands to `[{clipboard}]({clipboard})` when you've copied a URL.
- **Fill-in fields** -- named variables `{Name}` or `{Company}` trigger a small popover before pasting. You type the values; Summon assembles and pastes the completed expansion. This is TextExpander's most powerful feature.
- **Shell expansion** -- `{shell:date +%Y}` runs a shell command and inserts stdout. Power-user feature; opt-in only.
- **Cursor positioning** -- `{cursor}` marks where the cursor should land after expansion, so for templates you land in the right field.

---

## Phase 3: Organization and Discovery

**Goal:** Scale gracefully past 50 snippets.

- **Groups/folders** -- snippets belong to an optional group (Work, Personal, Code, Boilerplate). Manager shows group sidebar. Filter and search within groups.
- **Search aliases** -- a snippet can have multiple trigger strings, all pointing to the same expansion. Shown in the detail pane as "also triggers on: ;signature, ;sig, ;mysig."
- **Usage tracking** -- record how many times each snippet is expanded. Surface in the manager as a "most used" sorted view. Helps identify which snippets are earning their triggers.
- **Bulk import/export** -- JSON export of the full snippets table. Importer for TextExpander `.textexpander` bundles and CSV. Makes migration easy in both directions.
- **Snippet templates** -- a gallery of common starting snippets (email signatures, date formats, common boilerplate) shown on first run or via a "Browse templates" button.

---

## Phase 4: Sync and Sharing

**Goal:** Snippet library available across devices and optionally across team members.

- **iCloud sync** -- local-first by default; opt-in sync via iCloud Drive (copies SQLite WAL snapshots). No account required beyond the iCloud account you already have.
- **Team library** -- a shared snippet library with read-only access for team members and write access for designated owners. Distribution via a shared iCloud Drive folder or a simple Git repo.
- **iOS companion** -- view and trigger snippets from an iOS Share Sheet extension; useful for filling common responses in mobile email and messaging.

---

## Distribution

- **Homebrew cask** -- `brew install --cask summon`
- **Sparkle auto-update** -- in-app update check from GitHub releases
- **Notarization** -- Apple Developer ID for Gatekeeper

---

*Last updated: 2026-06*
