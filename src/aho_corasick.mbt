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
}

/// Build an Aho-Corasick automaton from a list of patterns.
///
/// ```moonbit
/// let ac = build(["valence", "moonbit", "helios"])
/// ```
pub fn build(patterns : Array[String]) -> AhoCorasick {
  let goto : Array[Map[Int, Int]] = [Map::from_array([])]
  let output : Array[Array[Int]] = [[]]
  let mut num_states = 1

  for pi in 0..<patterns.length() {
    let pattern = patterns[pi]
    let mut state = 0
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
    }
    output[state].push(pi)
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

  AhoCorasick::{ goto, fail, output, patterns }
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

/// Search text and return matched pattern strings.
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

/// Return the number of states in the automaton.
pub fn AhoCorasick::state_count(self : AhoCorasick) -> Int {
  self.goto.length()
}

/// Return the number of patterns.
pub fn AhoCorasick::pattern_count(self : AhoCorasick) -> Int {
  self.patterns.length()
}
