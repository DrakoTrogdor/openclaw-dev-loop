# bookmark-manager

An OpenClaw skill for saving, searching, and organizing web bookmarks.

## Structure

```
bookmark-manager/
├── SKILL.md                    ← skill definition
├── scripts/
│   └── bookmarks.sh           ← CLI for bookmark operations
└── references/
    ├── STORAGE.md              ← storage format and schema
    └── SEARCH.md               ← search algorithm docs
```

## Build & Test

```bash
./build.sh
```

The build script validates the skill structure and runs basic smoke tests on the bookmark CLI.

## Known Issues

See `STATUS.md` for current known issues.
