# aho-corasick

Multi-pattern string matching for MoonBit. Compiles patterns into a finite automaton, finds all occurrences in a single pass.

## Install

```bash
moon add helios-house/aho-corasick
```

## Usage

```moonbit
let ac = @aho_corasick.build(["they", "them", "their", "theirs"])

// Find all matching pattern indices
let matches = ac.search("they gave them their things")

// Get matched strings
let found = ac.find_all("building valence in moonbit")  // ["valence", "moonbit"]

// Check if any pattern matches (short-circuits)
let has_match = ac.contains_any("this has an error in it")
```

### Match positions

Find where each match occurs in the text:

```moonbit
let ac = @aho_corasick.build(["cat", "dog"])
let matches = ac.find_all_matches("the cat and the dog")
// Match { pattern: "cat", start: 4, end: 7, .. }
// Match { pattern: "dog", start: 16, end: 19, .. }
```

### Count, replace

```moonbit
let ac = @aho_corasick.build(["old", "stale"])

// Count all occurrences
ac.count("old is old and stale")  // 3

// Replace matched patterns
ac.replace("old is old and stale", ["new", "fresh"])
// "new is new and fresh"
```

### Case-insensitive matching

Lowercase patterns at build time, lowercase text before searching:

```moonbit
let ac = @aho_corasick.build(["error", "warning"])
let found = ac.find_all("Error: WARNING detected".to_lower())
// ["error", "warning"]
```

### Bytes search (faster for ASCII content)

Skip String iterator overhead when working with raw bytes:

```moonbit
let ac = @aho_corasick.build(["cat", "dog"])
let text : Bytes = b"the cat sat on the dog"
let matches = ac.search_bytes(text, text.length())
```

### Native acceleration (C flat-array automaton)

On native target, use the C-backed functions for maximum speed. Flat-array goto table, zero allocation during search, built-in ASCII case folding:

```moonbit
let ac = @aho_corasick.build(["error", "warn", "info"])
ac.build_native()  // builds the C-side automaton
let matches = ac.search_native("ERROR: connection INFO lost")  // case-insensitive
let found = ac.contains_any_native("a fatal warning")  // short-circuits
let n = ac.count_native("ab ab ab")  // total occurrences
let positions = ac.find_all_matches_native("the cat and the dog")  // with positions
```

Available on native target only. Wasm-gc and JS targets use the pure MoonBit implementation automatically.

## Complexity

- **Build:** O(m) where m = total length of all patterns
- **Search:** O(n + z) where n = text length, z = number of matches
- **Space:** O(m x alphabet) for the goto table

## API

| Function | Returns | Description |
|----------|---------|-------------|
| `build(patterns)` | `AhoCorasick` | Compile patterns into automaton |
| `.search(text)` | `Array[Int]` | Matched pattern indices (deduplicated) |
| `.search_bytes(data, len)` | `Array[Int]` | Pattern indices on raw bytes |
| `.find_all(text)` | `Array[String]` | Matched pattern strings |
| `.find_all_matches(text)` | `Array[Match]` | All matches with positions |
| `.find_all_matches_bytes(data, len)` | `Array[Match]` | Matches with byte positions |
| `.contains_any(text)` | `Bool` | Any match (short-circuits) |
| `.contains_any_bytes(data, len)` | `Bool` | Any match on bytes |
| `.count(text)` | `Int` | Total occurrence count |
| `.replace(text, replacements)` | `String` | Replace matches (longest-first) |
| `.state_count()` | `Int` | Automaton states |
| `.pattern_count()` | `Int` | Number of patterns |
| `.build_native()` | `Unit` | Build C automaton (native only) |
| `.search_native(text)` | `Array[Int]` | C-backed search with case folding (native only) |
| `.contains_any_native(text)` | `Bool` | C-backed short-circuit (native only) |
| `.count_native(text)` | `Int` | C-backed count (native only) |
| `.find_all_matches_native(text)` | `Array[Match]` | C-backed with positions (native only) |

## License

Apache-2.0
