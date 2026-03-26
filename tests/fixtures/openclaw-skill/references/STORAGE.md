# Storage Format

Bookmarks are stored as a JSON array in `~/.bookmarks/bookmarks.json`.

## Schema

Each bookmark entry:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| url | string | yes | Full URL |
| title | string | no | Page title (extracted or user-provided) |
| tags | string[] | no | Lowercase tag names |
| notes | string | no | Free-text notes |
| created | ISO 8601 | yes | When the bookmark was saved |
| accessed | ISO 8601 | yes | Last time the bookmark was accessed |

## Migration

If the bookmark file uses the legacy format (newline-delimited URLs), run:

```bash
bookmarks.sh migrate
```

This converts to the JSON format automatically.

> Note: The `migrate` command is planned but not yet implemented.
