# DEV-LOOP-CHECKLIST — Pass 2 (Self-Reflective)

Focus: adversarial creativity in finding issues + strict adherence to the DEV-LOOP spec.

## Project Commands
- **Build:** `./build.sh --msg "<description>"` (tests → sync → commit → push)
- **Test:** `./tests/run-tests.sh` (structural) or `./tests/run-tests.sh --mode integration` (full)
- **Deploy:** n/a (build.sh syncs to local skills dir)
- **Commit:** `./build.sh --msg "<description>"`
- **Lint:** n/a (shell scripts)

## Known issues from STATUS.md
- No STATUS.md at project root
