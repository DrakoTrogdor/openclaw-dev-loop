# counter

A simple CLI that counts occurrences of a word read from stdin.

## Usage

```
echo "some text" | counter --word <word> [--ignore-case]
```

## Options

- `--word <word>`    Word to search for (required)
- `--ignore-case`    Case-insensitive matching

## Build & Test

```bash
./build.sh
```

## Requirements

- Rust 1.70+
