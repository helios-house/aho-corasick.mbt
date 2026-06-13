/// Aho-Corasick multi-pattern string matching.
///
/// Compiles a set of patterns into a finite automaton that finds all
/// occurrences in a single pass through the text. Time complexity:
/// O(n + m + z) where n = text length, m = total pattern length,
/// z = number of matches.
///
/// For case-insensitive matching, lowercase your patterns at build time
/// and lowercase the text before searching.

/// The compiled Aho-Corasick automaton.
pub(all) struct AhoCorasick {
  goto : Array[Map[Int, Int]]
  fail : Array[Int]
  output : Array[Array[Int]]
  patterns : Array[String]
  pattern_lengths : Array[Int]
}

/// A match with position information.
pub(all) struct Match {
  pattern_index : Int
  pattern : String
  start : Int
  end : Int
} derive(Eq, Debug)

/// Build an Aho-Corasick automaton from a list of patterns.
///
/// ```moonbit
/// let ac = build(["valence", "moonbit", "helios"])
/// ```
pub fn build(patterns : Array[String]) -> AhoCorasick {
  let goto : Array[Map[Int, Int]] = [Map::from_array([])]
  let output : Array[Array[Int]] = [[]]
  let mut num_states = 1
  let pattern_lengths : Array[Int] = []

  for pi in 0..<patterns.length() {
    let pattern = patterns[pi]
    let mut state = 0
    let mut len = 0
    for ch in pattern {
      let c = ch.to_int()
      match goto[state].get(c) {
        Some(next) => state = next
        None => {
          let new_state = num_states
          num_states = num_states + 1
          goto[state][c] = new_state
          goto.push(Map::from_array([]))
          output.push([])
          state = new_state
        }
      }
      len = len + 1
    }
    output[state].push(pi)
    pattern_lengths.push(len)
  }

  let fail = Array::make(num_states, 0)
  let queue : Array[Int] = []

  for entry in goto[0] {
    let (_, s) = entry
    fail[s] = 0
    queue.push(s)
  }

  let mut qi = 0
  while qi < queue.length() {
    let r = queue[qi]
    qi = qi + 1

    for entry in goto[r] {
      let (c, s) = entry
      queue.push(s)

      let mut state = fail[r]
      while state != 0 && goto[state].get(c) is None {
        state = fail[state]
      }
      fail[s] = match goto[state].get(c) {
        Some(next) => if next == s { 0 } else { next }
        None => 0
      }

      for out in output[fail[s]] {
        output[s].push(out)
      }
    }
  }

  AhoCorasick::{ goto, fail, output, patterns, pattern_lengths }
}

/// Search text for all patterns. Returns indices of matched patterns (deduplicated).
///
/// ```moonbit
/// let ac = build(["error", "warn", "info"])
/// let matches = ac.search("error: connection info lost")
/// ```
pub fn AhoCorasick::search(self : AhoCorasick, text : String) -> Array[Int] {
  let found : Map[Int, Bool] = Map::from_array([])
  let mut state = 0

  for ch in text {
    let c = ch.to_int()
    while state != 0 && self.goto[state].get(c) is None {
      state = self.fail[state]
    }
    state = match self.goto[state].get(c) {
      Some(next) => next
      None => 0
    }
    for pi in self.output[state] {
      found[pi] = true
    }
  }

  let result : Array[Int] = []
  for entry in found {
    let (pi, _) = entry
    result.push(pi)
  }
  result
}

/// Search raw bytes for all patterns. Faster than String search — no iterator overhead.
/// Use when patterns are ASCII and text is available as Bytes.
///
/// ```moonbit
/// let ac = build(["cat", "dog"])
/// let text : Bytes = b"the cat sat on the dog"
/// let matches = ac.search_bytes(text, text.length())
/// ```
pub fn AhoCorasick::search_bytes(self : AhoCorasick, data : Bytes, len : Int) -> Array[Int] {
  let found : Map[Int, Bool] = Map::from_array([])
  let mut state = 0

  for i in 0..<len {
    let c = data[i].to_int()
    while state != 0 && self.goto[state].get(c) is None {
      state = self.fail[state]
    }
    state = match self.goto[state].get(c) {
      Some(next) => next
      None => 0
    }
    for pi in self.output[state] {
      found[pi] = true
    }
  }

  let result : Array[Int] = []
  for entry in found {
    let (pi, _) = entry
    result.push(pi)
  }
  result
}

/// Find all matches with their positions in the text.
///
/// Returns every occurrence — a pattern appearing three times produces three Match entries.
/// Matches are ordered by end position.
///
/// ```moonbit
/// let ac = build(["the", "he"])
/// let matches = ac.find_all_matches("the other the")
/// // Match { pattern: "the", start: 0, end: 3, .. }
/// // Match { pattern: "he", start: 1, end: 3, .. }
/// // ...
/// ```
pub fn AhoCorasick::find_all_matches(self : AhoCorasick, text : String) -> Array[Match] {
  let result : Array[Match] = []
  let mut state = 0
  let mut pos = 0

  for ch in text {
    let c = ch.to_int()
    while state != 0 && self.goto[state].get(c) is None {
      state = self.fail[state]
    }
    state = match self.goto[state].get(c) {
      Some(next) => next
      None => 0
    }
    pos = pos + 1
    for pi in self.output[state] {
      let plen = self.pattern_lengths[pi]
      result.push(
        Match::{
          pattern_index: pi,
          pattern: self.patterns[pi],
          start: pos - plen,
          end: pos,
        },
      )
    }
  }
  result
}

/// Find all matches with byte positions.
pub fn AhoCorasick::find_all_matches_bytes(
  self : AhoCorasick,
  data : Bytes,
  len : Int
) -> Array[Match] {
  let result : Array[Match] = []
  let mut state = 0

  for i in 0..<len {
    let c = data[i].to_int()
    while state != 0 && self.goto[state].get(c) is None {
      state = self.fail[state]
    }
    state = match self.goto[state].get(c) {
      Some(next) => next
      None => 0
    }
    let pos = i + 1
    for pi in self.output[state] {
      let plen = self.pattern_lengths[pi]
      result.push(
        Match::{
          pattern_index: pi,
          pattern: self.patterns[pi],
          start: pos - plen,
          end: pos,
        },
      )
    }
  }
  result
}

/// Search text and return matched pattern strings (deduplicated).
///
/// ```moonbit
/// let ac = build(["valence", "moonbit", "helios"])
/// ac.find_all("building valence in moonbit for helios")
/// // ["valence", "moonbit", "helios"]
/// ```
pub fn AhoCorasick::find_all(self : AhoCorasick, text : String) -> Array[String] {
  let indices = self.search(text)
  let result : Array[String] = []
  for pi in indices {
    result.push(self.patterns[pi])
  }
  result
}

/// Check if any pattern matches in the text. Short-circuits on first match.
///
/// ```moonbit
/// let ac = build(["error", "warning", "fatal"])
/// ac.contains_any("no errors here")  // true
/// ```
pub fn AhoCorasick::contains_any(self : AhoCorasick, text : String) -> Bool {
  let mut state = 0
  for ch in text {
    let c = ch.to_int()
    while state != 0 && self.goto[state].get(c) is None {
      state = self.fail[state]
    }
    state = match self.goto[state].get(c) {
      Some(next) => next
      None => 0
    }
    if self.output[state].length() > 0 {
      return true
    }
  }
  false
}

/// Check if any pattern matches in raw bytes. Short-circuits on first match.
pub fn AhoCorasick::contains_any_bytes(self : AhoCorasick, data : Bytes, len : Int) -> Bool {
  let mut state = 0
  for i in 0..<len {
    let c = data[i].to_int()
    while state != 0 && self.goto[state].get(c) is None {
      state = self.fail[state]
    }
    state = match self.goto[state].get(c) {
      Some(next) => next
      None => 0
    }
    if self.output[state].length() > 0 {
      return true
    }
  }
  false
}

/// Count total number of matches (including duplicates at different positions).
///
/// ```moonbit
/// let ac = build(["ab"])
/// ac.count("ababab")  // 3
/// ```
pub fn AhoCorasick::count(self : AhoCorasick, text : String) -> Int {
  let mut total = 0
  let mut state = 0
  for ch in text {
    let c = ch.to_int()
    while state != 0 && self.goto[state].get(c) is None {
      state = self.fail[state]
    }
    state = match self.goto[state].get(c) {
      Some(next) => next
      None => 0
    }
    total = total + self.output[state].length()
  }
  total
}

/// Replace all occurrences of matched patterns with their replacements.
/// `replacements` must have the same length as the patterns used to build the automaton.
/// When patterns overlap, the longest match at each position wins.
///
/// ```moonbit
/// let ac = build(["cat", "dog"])
/// ac.replace("the cat and the dog", ["feline", "canine"])
/// // "the feline and the canine"
/// ```
pub fn AhoCorasick::replace(
  self : AhoCorasick,
  text : String,
  replacements : Array[String]
) -> String {
  let matches = self.find_all_matches(text)
  if matches.length() == 0 {
    return text
  }
  // Greedy left-to-right: pick the longest match at each position, skip overlaps
  let sorted = matches.copy()
  sorted.sort_by(fn(a, b) {
    if a.start < b.start {
      -1
    } else if a.start > b.start {
      1
    } else if (a.end - a.start) > (b.end - b.start) {
      -1
    } else if (a.end - a.start) < (b.end - b.start) {
      1
    } else {
      0
    }
  })

  let sb = StringBuilder::new()
  let chars : Array[Char] = []
  for ch in text {
    chars.push(ch)
  }

  let mut pos = 0
  for m in sorted {
    if m.start < pos {
      continue
    }
    while pos < m.start {
      sb.write_char(chars[pos])
      pos = pos + 1
    }
    sb.write_string(replacements[m.pattern_index])
    pos = m.end
  }
  while pos < chars.length() {
    sb.write_char(chars[pos])
    pos = pos + 1
  }
  sb.to_string()
}

/// Return the number of states in the automaton.
pub fn AhoCorasick::state_count(self : AhoCorasick) -> Int {
  self.goto.length()
}

/// Return the number of patterns.
pub fn AhoCorasick::pattern_count(self : AhoCorasick) -> Int {
  self.patterns.length()
}
