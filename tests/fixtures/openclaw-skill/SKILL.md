---
name: bookmark-manager
description: Save, search, and organize web bookmarks with tags and notes. Use when the user asks to save a URL, search bookmarks, list bookmarks by tag, or manage their bookmark collection. Also triggers on phrases like "bookmark this", "save this link", "find that bookmark", or "show my bookmarks".
---

# Bookmark Manager

Manage web bookmarks with tags, notes, and full-text search.

## Quick Start

1. Save a bookmark: provide a URL, optional title, tags, and notes
2. Search: by tag, keyword, or date range
3. List: all bookmarks or filtered by tag

## Commands

### Save a bookmark

```
save <url> [--title <title>] [--tags <tag1,tag2>] [--notes <text>]
```

Saves the URL to the local bookmark store at `~/.bookmarks/bookmarks.json`.

### Search bookmarks

```
search <query> [--tag <tag>] [--limit <n>]
```

Searches title, URL, notes, and tags. Default limit: 10.

### Delete a bookmark

```
delete <url>
```

Removes the bookmark matching the given URL.

### Export bookmarks

```
export [--format html|json|csv]
```

Exports all bookmarks in the specified format. Default: json.

## Storage

Bookmarks are stored in `~/.bookmarks/bookmarks.json` as a JSON array. Each entry:

```json
{
  "url": "https://example.com",
  "title": "Example",
  "tags": ["reference", "docs"],
  "notes": "A useful example site",
  "created": "2026-01-15T10:30:00Z",
  "accessed": "2026-03-20T14:00:00Z"
}
```

## References

- Storage format and migration details: `references/STORAGE.md`
- Search algorithm and ranking: `references/SEARCH.md`
