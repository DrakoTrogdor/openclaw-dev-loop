// counter — counts occurrences of a word in stdin
//
// PLANTED FLAWS (for dev-loop testing):
//   [Step 1]  README documents --ignore-case flag; not implemented in code.
//   [Step 2]  Help text says "Counts lines containing <word>" but code counts occurrences.
//   [Step 3a] Empty --word "" causes .matches("") to return infinite matches (panics or hangs).
//   [Step 3b] .unwrap() on line read — silently panics on invalid UTF-8 instead of handling error.
//   [Step 3c] Unused import: `use std::collections::HashMap;`
//   [Step 3E] Counting is per-line. If word spans a line boundary (e.g. "hel\nlo" for "hello"),
//             it's silently missed. The logic looks correct because .matches() works fine on each
//             line individually — only adversarial thinking about input shaping catches this.

use std::collections::HashMap; // unused import — [Step 3c]
use std::io::{self, BufRead};
use std::env;

fn count_word(reader: impl BufRead, word: &str) -> usize {
    // BUG [Step 3a]: "".matches("") panics or produces nonsensical results
    // BUG [Step 3E]: per-line counting misses words that span line boundaries
    let mut total = 0;
    for line in reader.lines() {
        let line = line.unwrap(); // BUG [Step 3b]: panics on invalid UTF-8 instead of error handling
        total += line.matches(word).count();
    }
    total
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() != 3 || args[1] != "--word" {
        // BUG [Step 2]: says "Counts lines containing" but actually counts occurrences
        eprintln!("Usage: counter --word <word>");
        eprintln!("Counts lines containing <word> from stdin");
        // NOTE: --ignore-case documented in README but not implemented [Step 1]
        std::process::exit(1);
    }

    let word = &args[2];
    let stdin = io::stdin();
    let reader = stdin.lock();

    let count = count_word(reader, word);
    println!("{}", count);
}
