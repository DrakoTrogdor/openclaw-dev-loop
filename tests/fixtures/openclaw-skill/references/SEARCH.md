# Search Algorithm

## Keyword Search

Searches across title, URL, and notes fields using case-insensitive substring matching.

Results are returned in insertion order (most recent last).

## Tag Search

When `--tag` is provided, filters bookmarks to those containing the exact tag.

Tag matching is case-sensitive to ensure precise filtering.

> Note: This is a known inconsistency — tags are stored lowercase, but search is case-sensitive.
> A future update should normalize the search query to lowercase before matching.

## Date Range Search

Search supports filtering by date range using `--after` and `--before` flags:

```
search <query> --after 2026-01-01 --before 2026-03-01
```

This filters results to bookmarks created within the specified range.

> Note: Date range filtering is documented here but not yet implemented in the script.
