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

## Complexity

- **Build:** O(m) where m = total length of all patterns
- **Search:** O(n + z) where n = text length, z = number of matches
- **Space:** O(m × alphabet) for the goto table

## API

- `build(patterns : Array[String]) -> AhoCorasick` — compile patterns into automaton
- `AhoCorasick::search(text : String) -> Array[Int]` — matched pattern indices
- `AhoCorasick::search_bytes(data : Bytes, len : Int) -> Array[Int]` — matched pattern indices on raw bytes
- `AhoCorasick::find_all(text : String) -> Array[String]` — matched pattern strings
- `AhoCorasick::contains_any(text : String) -> Bool` — any match (short-circuits)
- `AhoCorasick::contains_any_bytes(data : Bytes, len : Int) -> Bool` — any match on raw bytes
- `AhoCorasick::state_count() -> Int` — number of automaton states
- `AhoCorasick::pattern_count() -> Int` — number of patterns

## License

Apache-2.0
