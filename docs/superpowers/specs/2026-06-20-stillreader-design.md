# Stillreader — Product & Technical Design

**Date:** 2026-06-20  
**Status:** Approved  
**Repo:** greenfield SwiftUI multiplatform app

## One-sentence goal

Build a native reader app where the user's markdown files in their own cloud are the database, and the app is a fast, friendly client that syncs, caches, and renders on top of them.

## Product principles

1. **The app is the interface; the markdown files are the system of record.** Not a markdown editor with RSS features, and not a feed reader that exports as an afterthought.
2. **Archive your relationship to the web, not the web itself.** Subscriptions, saved links, read state, tags, and notes live in files. RSS article bodies are ephemeral cache.
3. **Feel like a normal app.** Inbox, refresh, read/unread, tags, search, calm reading UI — powered by a fast local cache merged with portable files.
4. **You own the data.** Files live in iCloud Drive (v1), visible in Files/Finder. If Stillreader disappears, subscriptions and state remain.
5. **Calm technology.** On-demand refresh only. No push notifications (v1). No background polling. Explicit "last refreshed." The app asks for attention when you open it.
6. **Agents-ready.** An AI or script can add a feed or save a link by writing the same markdown files — no proprietary API.
7. **Minimal hosted infrastructure (v1).** Client-side RSS fetch. No subscription database on a server. Optional fetch proxy deferred to v2.
8. **Storage is pluggable.** iCloud ships in v1; GitHub follows via the same folder layout and a `StorageProvider` adapter.

## Decisions log

| Area | Decision |
|------|----------|
| Architecture | **A — Files-first, thin local cache** (see below) |
| Storage v1 | iCloud Drive |
| Storage v2 | GitHub (same file layout, adapter swap) |
| Platform | SwiftUI multiplatform — **iPhone + Mac in v1**; iPad and others later |
| v1 scope | Full replacement: RSS, link saver, tags, notes, OPML import, share extension, search |
| Personal migration | Clean slate; import tooling ships for others and future use |
| Feed fetch | Client-only v1 via `FeedFetcher` protocol; proxy adapter deferred |
| Link saving | Share extension (iOS + macOS) |
| Reading | Excerpt view → optional in-app WebView → Safari fallback |
| Search | Local title/excerpt search with tag and read/unread filters |
| External files | Visible in Files/Finder; **new** `feeds/` and `links/` files imported; edits to existing files ignored |
| App Store | Standard iCloud + App Group; no blockers for any architectural option |

## Architecture (Approach A)

Markdown in iCloud is the system of record. The app keeps a **local SQLite cache** only for ephemeral RSS items and fast search. Subscriptions, links, and read state are read from and written to `.md` files directly.

```
Markdown files  =  what you own (subscriptions, state, links)
SQLite cache    =  what the app remembers temporarily (RSS items, search index)
```

### Why not alternatives

- **SwiftData mirror:** Two sources of truth; drift between DB and files undermines the product promise.
- **Append-only event log:** Over-engineered for v1; harder to read and edit by hand.

### Component diagram

```
┌─────────────────────────────────────────────────┐
│              Stillreader App (SwiftUI)           │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Reader UI│  │ Share Ext│  │ Import (OPML) │  │
│  └────┬─────┘  └────┬─────┘  └───────┬───────┘  │
│       └─────────────┼────────────────┘          │
│              ┌──────▼──────┐                   │
│              │  App Core   │                   │
│              │ (merge/sync)│                   │
│              └──┬───────┬──┘                   │
│     ┌───────────┘       └───────────┐          │
│  ┌──▼──────────┐            ┌───────▼───────┐  │
│  │StorageProvider│          │ FeedFetcher   │  │
│  │  (protocol)  │          │  (protocol)   │  │
│  └──┬──────────┘            └───────┬───────┘  │
│  ┌──▼──────────┐            ┌───────▼───────┐  │
│  │ iCloudAdapter│           │ DirectFetcher │  │
│  └─────────────┘            └───────────────┘  │
│  ┌─────────────┐                               │
│  │ GitHubAdapter│  (v2 stub)                  │
│  └─────────────┘                               │
└─────────────────────────────────────────────────┘
         │                              │
    iCloud Drive                   RSS feeds
    (markdown files)               (ephemeral)
```

### Three layers

1. **Persistent markdown** (iCloud) — subscriptions, saved links, read state
2. **Local cache** (SQLite) — RSS items, fetch timestamps, search index
3. **App core** — merges cache + files into inbox views; writes state back to files on user actions

### Core rule

User actions (mark read, tag, save link) → write markdown immediately → update local index. Refresh → fetch RSS → update cache only → merge with state files for unread counts.

## File layout & markdown schema

Root folder in iCloud Drive: `Stillreader/`

```
Stillreader/
├── feeds/
│   ├── smashing-magazine.md
│   └── daring-fireball.md
├── links/
│   ├── 2026-06-20-layout-grid-tricks.md
│   └── 2026-06-18-swift-concurrency.md
├── state/
│   ├── smashing-magazine.md
│   └── daring-fireball.md
└── .stillreader/
    └── meta.yaml
```

The `.stillreader/` folder is app-managed and not intended for hand-editing. All other paths are human-readable.

### `feeds/{slug}.md` — subscriptions

One file per feed. Slug derived from title (e.g. `smashing-magazine`).

```yaml
---
id: "feed_smashing_magazine"       # stable UUID, never changes
title: "Smashing Magazine"
url: "https://www.smashingmagazine.com/feed/"
site_url: "https://www.smashingmagazine.com"
tags: ["design", "css"]
created: 2026-06-20T10:00:00Z
---
Notes on why I follow this feed.
```

- **App creates/updates:** title, url, tags, notes body
- **External add:** new file with at minimum `url` + `title` → app assigns `id` and slug on import
- **External edit to existing:** ignored

### `links/{date}-{slug}.md` — saved links

One file per saved link (share extension or in-app).

```yaml
---
id: "link_abc123"
url: "https://example.com/article"
title: "Layout Grid Tricks"
tags: ["design", "read-later"]
saved: 2026-06-20T14:30:00Z
read: false
---
Optional notes about why I saved this.
```

When read: set `read: true` and add `read_at` timestamp.

- Share extension writes minimal file (URL + fetched title); main app enriches on sync
- External rules: new files imported; edits to existing ignored

### `state/{feed-slug}.md` — read/unread for RSS

One file per feed. Records relationship to cached articles — not the articles themselves.

```yaml
---
feed_id: "feed_smashing_magazine"
updated: 2026-06-20T15:00:00Z
items:
  - id: "https://smashingmagazine.com/2026/06/article-slug/"
    status: read
    read_at: 2026-06-20T12:00:00Z
    tags: ["inspiration"]
  - id: "https://smashingmagazine.com/2026/06/other/"
    status: read_later
    tagged_at: 2026-06-20T11:00:00Z
    tags: ["todo"]
---
```

**Status values:** `read`, `read_later`, or omitted (= unread).

**Merge logic:** Unread inbox = RSS items in cache whose `id` is not listed with status `read`.

Per-article tags live in state files, not in cache.

### `.stillreader/meta.yaml` — app metadata

```yaml
schema_version: 1
last_refresh: 2026-06-20T15:00:00Z
feeds_refreshed:
  - id: "feed_smashing_magazine"
    refreshed_at: 2026-06-20T15:00:00Z
    item_count: 42
    error: null
```

Supports "last refreshed" UI and per-feed error display.

### ID rules

| Entity | ID source |
|--------|-----------|
| Feed | App-generated UUID on create |
| Link | App-generated UUID on save |
| RSS item | RSS `guid`, falling back to canonical `link` URL |

Stable IDs ensure read state survives refreshes when titles or excerpts change.

### What never goes in markdown

- Full article HTML or text
- Parsed RSS bodies beyond excerpt (excerpt lives in cache only)
- Search index
- UI preferences (stored in UserDefaults / app settings)

## Sync, refresh & merge

### Sync loop (files are truth)

**Triggers:** app launch, return to foreground, after user write, iCloud external change notification.

1. `StorageProvider.list()` / `read()` all known paths
2. New `feeds/*.md` or `links/*.md` → import (assign id, slug, index)
3. Known files changed by app → update local index
4. External edit to existing file → ignore (keep app version)
5. Deleted file → remove from index (feed delete confirms removal of paired `state/` file)

**Write path:** user action → update markdown → `StorageProvider.write()` → iCloud upload → update local index → optimistic UI update.

**Multi-device:** iPhone and Mac share one iCloud container. Last write wins per file (acceptable v1). Re-merge on foreground when iCloud delivers updates.

**Share extension:** writes `links/*.md` via App Group container; main app imports on next foreground.

### Refresh loop (cache is ephemeral)

**Triggers:** user taps Refresh (global or per-feed). No background polling.

1. For each feed: `FeedFetcher.fetch(url)`
2. Success → parse → upsert SQLite cache → update `meta.yaml`
3. Failure → record error in `meta.yaml`; show in UI; retain stale cache
4. Rebuild search index; re-run merge; update "last refreshed"

**Cache retention:** 30 days from last seen in a successful refresh. Prune old entries; `state/` files unaffected.

**Offline:** show cached inbox with stale indicator; read/unread still works.

### Merge loop (inbox is derived)

Runs after sync, refresh, or state change.

| View | Logic |
|------|-------|
| Unread RSS | cache items minus `state/` entries with `status: read` |
| Read later | `state/` entries with `status: read_later` (survives cache prune; open in browser if cache gone) |
| Saved links | `links/*.md` where `read: false` |
| Tag filter | intersection with tags on state items or link frontmatter |
| Search | SQLite FTS on cached titles/excerpts + link titles, with active filters |

### External file import

| Found | Action |
|-------|--------|
| New `feeds/*.md` with valid `url` | Import subscription; assign `id`; cache on next refresh |
| New `feeds/*.md` missing `url` | Skip; surface in Sync issues |
| New `links/*.md` with valid `url` | Add to saved links |
| Edit to existing file | Ignored |

## App UI & components

### Module structure

```
StillreaderApp
├── Core/           StorageProvider, FeedFetcher, parsers, merge, sync, refresh, search
├── Models/         Feed, Link, StateItem, CachedArticle, InboxItem (derived)
├── Features/       Inbox, Feeds, Links, Reader, Search, Import
├── ShareExtension/
└── Settings/
```

### iPhone navigation

Tab bar: **Inbox** · **Feeds** · **Links** · **Search**

- Inbox item tap → Reader (excerpt → WebView → Safari)
- Swipe: mark read · read later · tag
- Pull to refresh on Inbox and Feeds

### Mac navigation

`NavigationSplitView`: sidebar (four sections) · list · detail/reader pane.

Keyboard shortcuts: `R` refresh, `U` unread, `D` mark read, `L` read later.

### Key screens

- **Inbox:** calm list with "Last refreshed …" header and Refresh button
- **Feed detail:** editable tags/notes, per-feed refresh, mark all read
- **Reader:** excerpt, actions, optional WebView
- **Links:** unread-first saved links
- **Import:** OPML paste/file pick, preview with dedupe by URL
- **Settings:** iCloud status, sort preference, cache retention note, schema version

### Share extension

Minimal confirmation UI. Receives URL → fetch title (best effort) → write `links/{date}-{slug}.md` → dismiss.

### Explicitly out of v1 UI

Push notifications, background refresh, infinite scroll, account login, GitHub connection UI.

## Error handling & edge cases

| Scenario | Behavior |
|----------|----------|
| Feed fetch failure | Per-feed error in `meta.yaml`; warning in UI; stale cache retained |
| Malformed markdown | Skip file; list in Settings → Sync issues |
| iCloud unavailable | Full offline mode; queue writes; banner when offline |
| Duplicate URL on import | Dedupe; OPML shows "N new, M already subscribed" |
| Read later + pruned cache | Show from state with "Open in Safari" |
| Slug collision | Append `-2`, `-3`; `id` remains stable |
| Feed deletion | Confirm; delete `feeds/` + `state/`; prune cache |

## Testing approach

### Unit tests

- MarkdownParser round-trip
- MergeEngine with fixture cache + state
- Slug generation and URL dedupe
- OPML parser

### Integration tests

- `StorageProvider` against temp directory (no iCloud in CI)
- End-to-end: write feed → mock refresh → merge → mark read → verify state file

### Manual pre-release checklist

- Fresh install → add feed → refresh → read → verify Files app
- Share extension → Links tab
- OPML import (50+ feeds)
- iPhone + Mac sync
- Offline mark read → reconnect
- External `feeds/new.md` in Finder → import on launch

### Out of scope for automated v1 tests

WebView rendering, live iCloud, live RSS network in CI.

## App Store notes

All architectural options are App Store eligible. Approach A uses standard iCloud Documents and App Groups (share extension). Client-side RSS requires no operated backend in v1. Privacy disclosure stays minimal.

## Future (post-v1)

- GitHub `StorageProvider` adapter (same folder layout)
- `ProxyFeedFetcher` for problematic feeds
- Shortcuts action
- iPad-optimized layout
- Full-text search across markdown notes bodies
