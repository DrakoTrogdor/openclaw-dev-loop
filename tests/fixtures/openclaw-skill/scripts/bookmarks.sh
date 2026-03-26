#!/usr/bin/env bash
# bookmarks.sh — CLI for managing bookmarks
#
# PLANTED FLAWS (for dev-loop testing):
#   [Step 1]  SKILL.md documents "export" command with --format csv; script only supports html|json.
#   [Step 2]  --help says "search by date range" but date filtering is not implemented.
#   [Step 3a] save_bookmark doesn't validate URL format — accepts empty string or garbage.
#   [Step 3b] delete_bookmark uses grep -v to remove entries — silently deletes ALL bookmarks
#             if the URL contains regex metacharacters (e.g. "https://example.com?q=foo+bar").
#   [Step 3c] Unused variable: BACKUP_DIR is defined but never used.
#   [Step 3E] search_bookmarks uses case-sensitive grep on tags, but save_bookmark lowercases
#             tags on save. A search for "Docs" will never match the tag "docs" — the code
#             looks correct in isolation (grep works, lowercase works) but the interaction
#             between save and search is broken. Only adversarial review catches this.

set -euo pipefail

BOOKMARK_FILE="${BOOKMARK_DIR:-$HOME/.bookmarks}/bookmarks.json"
BACKUP_DIR="${BOOKMARK_DIR:-$HOME/.bookmarks}/backups"  # unused — [Step 3c]

usage() {
  cat <<EOF
Usage: bookmarks.sh <command> [options]

Commands:
  save <url> [--title <t>] [--tags <t1,t2>] [--notes <text>]
  search <query> [--tag <tag>] [--limit <n>]
  delete <url>
  export [--format html|json]

Search supports keyword matching on title, URL, notes, and tags.
Supports search by date range for created/accessed timestamps.
EOF
# BUG [Step 2]: "search by date range" claimed above but not implemented
}

ensure_store() {
  local dir
  dir="$(dirname "$BOOKMARK_FILE")"
  mkdir -p "$dir"
  if [[ ! -f "$BOOKMARK_FILE" ]]; then
    echo '[]' > "$BOOKMARK_FILE"
  fi
}

save_bookmark() {
  local url="$1" title="${2:-}" tags="${3:-}" notes="${4:-}"
  # BUG [Step 3a]: no URL validation — accepts empty string, spaces, anything
  ensure_store

  # Lowercase tags before saving
  tags="$(echo "$tags" | tr '[:upper:]' '[:lower:]')"

  local created
  created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Append to JSON file (simplified — uses python for JSON manipulation)
  python3 -c "
import json, sys
with open('$BOOKMARK_FILE', 'r') as f:
    data = json.load(f)
data.append({
    'url': '$url',
    'title': '$title',
    'tags': [t.strip() for t in '$tags'.split(',') if t.strip()],
    'notes': '$notes',
    'created': '$created',
    'accessed': '$created'
})
with open('$BOOKMARK_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
  echo "Saved: $url"
}

search_bookmarks() {
  local query="$1" tag="${2:-}" limit="${3:-10}"
  ensure_store

  if [[ -n "$tag" ]]; then
    # BUG [Step 3E]: case-sensitive grep on tags, but tags are stored lowercase
    # Searching for "Docs" won't match "docs" — save lowercases, search doesn't
    grep -l "\"$tag\"" "$BOOKMARK_FILE" > /dev/null 2>&1 || true
    python3 -c "
import json
with open('$BOOKMARK_FILE') as f:
    data = json.load(f)
results = [b for b in data if '$tag' in b.get('tags', [])]
for b in results[:$limit]:
    print(f\"{b['title']} — {b['url']}\")
"
  else
    python3 -c "
import json
with open('$BOOKMARK_FILE') as f:
    data = json.load(f)
q = '$query'.lower()
results = [b for b in data if q in b.get('title','').lower() or q in b.get('url','').lower() or q in b.get('notes','').lower()]
for b in results[:$limit]:
    print(f\"{b['title']} — {b['url']}\")
"
  fi
}

delete_bookmark() {
  local url="$1"
  ensure_store
  # BUG [Step 3b]: grep -v with unescaped URL — regex metacharacters in URL
  # will match (and delete) unrelated bookmarks. E.g. "example.com?q=foo+bar"
  # treats . ? + as regex special chars
  local tmp
  tmp="$(mktemp)"
  grep -v "$url" "$BOOKMARK_FILE" > "$tmp" || true
  mv "$tmp" "$BOOKMARK_FILE"
  echo "Deleted: $url"
}

export_bookmarks() {
  local format="${1:-json}"
  ensure_store

  case "$format" in
    json)
      cat "$BOOKMARK_FILE"
      ;;
    html)
      python3 -c "
import json
with open('$BOOKMARK_FILE') as f:
    data = json.load(f)
print('<html><body><ul>')
for b in data:
    print(f\"<li><a href='{b[\"url\"]}'>{b['title']}</a></li>\")
print('</ul></body></html>')
"
      ;;
    # NOTE: csv format documented in SKILL.md but not implemented [Step 1]
    *)
      echo "ERROR: Unknown format: $format (supported: html, json)"
      exit 1
      ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

CMD="$1"
shift

case "$CMD" in
  save)
    url="${1:-}"
    title="" tags="" notes=""
    shift || true
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --title) title="$2"; shift 2 ;;
        --tags)  tags="$2";  shift 2 ;;
        --notes) notes="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
      esac
    done
    save_bookmark "$url" "$title" "$tags" "$notes"
    ;;
  search)
    query="${1:-}"
    tag="" limit="10"
    shift || true
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --tag)   tag="$2";   shift 2 ;;
        --limit) limit="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
      esac
    done
    search_bookmarks "$query" "$tag" "$limit"
    ;;
  delete)
    delete_bookmark "${1:?URL required}"
    ;;
  export)
    export_bookmarks "${1:-json}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $CMD"
    usage
    exit 1
    ;;
esac
