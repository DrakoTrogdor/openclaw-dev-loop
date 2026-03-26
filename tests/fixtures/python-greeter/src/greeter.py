"""
greeter — a simple CLI that greets users by name.

PLANTED FLAWS (for dev-loop testing):
  [Step 1]  README documents --reverse flag; this flag does not exist in the code.
  [Step 2]  --times help text says "default: 1" but argparse default is 3.
  [Step 3a] times loop has no guard against times <= 0 (infinite loop on --times 0).
  [Step 3b] name.encode() result is silently discarded; the intent was validation.
  [Step 3c] Unused import: `os`.
  [Step 3E] build_greeting doesn't validate name; empty string produces "Hello, !"
            and shout mode produces "HELLO, !" — grammatically broken output that
            looks correct in a code review because the logic is technically right.
"""

import argparse
import os  # unused import — [Step 3c]


def build_greeting(name: str, shout: bool) -> str:
    # BUG [Step 3E]: no validation on name — empty string produces "Hello, !"
    # and shout produces "HELLO, !" — the logic is "correct" (f-string works,
    # upper() works) but the output is grammatically broken. A standard code
    # review will see working code; an adversarial reviewer will ask "what
    # happens when name is empty?" and catch the broken output.
    greeting = f"Hello, {name}!"
    if shout:
        return greeting.upper()
    return greeting


def main():
    parser = argparse.ArgumentParser(description="Greet a user by name.")
    parser.add_argument("--name", required=True, help="Name to greet")
    parser.add_argument("--shout", action="store_true", help="Print greeting in uppercase")
    # BUG [Step 2]: help says default 1 but actual default is 3
    parser.add_argument("--times", type=int, default=3, help="Repeat the greeting N times (default: 1)")
    # NOTE: --reverse is documented in README but not implemented here [Step 1]

    args = parser.parse_args()

    # BUG [Step 3b]: encode result discarded — intent was to catch non-ASCII names
    args.name.encode("ascii")

    # BUG [Step 3a]: no guard — times=0 loops forever
    i = 0
    while i < args.times:
        print(build_greeting(args.name, args.shout))
        i += 1


if __name__ == "__main__":
    main()
