"""Tests for greeter CLI."""
import subprocess
import sys
import os

GREETER = os.path.join(os.path.dirname(__file__), "..", "src", "greeter.py")


def run(*args):
    result = subprocess.run(
        [sys.executable, GREETER] + list(args),
        capture_output=True, text=True
    )
    return result


def test_basic_greeting():
    r = run("--name", "Alice", "--times", "1")
    assert r.returncode == 0
    assert "Hello, Alice!" in r.stdout


def test_shout():
    r = run("--name", "Alice", "--shout", "--times", "1")
    assert r.returncode == 0
    assert "HELLO, ALICE!" in r.stdout


def test_times():
    r = run("--name", "Bob", "--times", "3")
    assert r.returncode == 0
    assert r.stdout.count("Hello, Bob!") == 3


def test_missing_name():
    r = run()
    assert r.returncode != 0
