# aho-corasick

Multi-pattern string matching for MoonBit. Compiles patterns into a finite automaton, finds all occurrences in a single pass.

## Install

```bash
moon add helios-house/aho-corasick
```

## Usage

```moonbit
let ac = @aho_corasick.build(["he", "she", "his", "hers"])

// Find all matching pattern indices
let matches = ac.search("ushers")

// Get matched strings
let found = ac.find_all("hello world")  // ["hello", "world"]

// Check if any pattern matches (short-circuits)
let has_match = ac.contains_any("some text")
```

### Case-insensitive matching

Lowercase patterns at build time, lowercase text before searching:

```moonbit
let ac = @aho_corasick.build(["error", "warning"])
let found = ac.find_all("Error: WARNING detected".to_lower())
// ["error", "warning"]
```

## Complexity

- **Build:** O(m) where m = total length of all patterns
- **Search:** O(n + z) where n = text length, z = number of matches
- **Space:** O(m × alphabet) for the goto table

## API

- `build(patterns : Array[String]) -> AhoCorasick` — compile patterns into automaton
- `AhoCorasick::search(text : String) -> Array[Int]` — matched pattern indices
- `AhoCorasick::find_all(text : String) -> Array[String]` — matched pattern strings
- `AhoCorasick::contains_any(text : String) -> Bool` — any match (short-circuits)
- `AhoCorasick::state_count() -> Int` — number of automaton states
- `AhoCorasick::pattern_count() -> Int` — number of patterns

## License

Apache-2.0
