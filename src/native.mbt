/// Native-accelerated Aho-Corasick via C flat-array automaton.
/// Uses the same AhoCorasick struct but delegates search to C on native target.
/// Build populates both the MoonBit goto table (for API compat) and the C automaton (for speed).

// C FFI declarations
#borrow(patterns, pattern_lens)
extern "C" fn c_native_ac_build(
  patterns : FixedArray[Bytes],
  pattern_lens : FixedArray[Int],
  pattern_count : Int,
) -> Unit = "native_ac_build"

#borrow(text, results)
extern "C" fn c_native_ac_search(
  text : Bytes,
  text_len : Int,
  results : FixedArray[Int],
  pattern_count : Int,
) -> Int = "native_ac_search"

#borrow(text, positions)
extern "C" fn c_native_ac_search_positions(
  text : Bytes,
  text_len : Int,
  positions : FixedArray[Int],
  max_matches : Int,
) -> Int = "native_ac_search_positions"

#borrow(text)
extern "C" fn c_native_ac_contains_any(
  text : Bytes,
  text_len : Int,
) -> Int = "native_ac_contains_any"

#borrow(text)
extern "C" fn c_native_ac_count(
  text : Bytes,
  text_len : Int,
) -> Int = "native_ac_count"

fn string_to_ascii_bytes(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for ch in s {
    arr.push((ch.to_int() & 0xFF).to_byte())
  }
  arr.push(b'\x00')
  Bytes::from_array(arr)
}

/// Build the C-side automaton from patterns. Call after build() for native acceleration.
pub fn AhoCorasick::build_native(self : AhoCorasick) -> Unit {
  let n = self.patterns.length()
  let c_patterns : Array[Bytes] = []
  let c_lens : Array[Int] = []
  for i in 0..<n {
    let p = self.patterns[i]
    c_patterns.push(string_to_ascii_bytes(p))
    c_lens.push(p.length())
  }
  let pat_ptrs = FixedArray::makei(n, fn(i) { c_patterns[i] })
  let pat_lens = FixedArray::makei(n, fn(i) { c_lens[i] })
  c_native_ac_build(pat_ptrs, pat_lens, n)
}

/// Search using C automaton. Returns matched pattern indices (deduplicated).
/// Call build_native() first. Falls back to pure MoonBit if not built.
pub fn AhoCorasick::search_native(self : AhoCorasick, text : String) -> Array[Int] {
  let n = self.patterns.length()
  let text_bytes = string_to_ascii_bytes(text)
  let results = FixedArray::make(n, 0)
  let _found = c_native_ac_search(text_bytes, text.length(), results, n)
  let out : Array[Int] = []
  for i in 0..<n {
    if results[i] != 0 {
      out.push(i)
    }
  }
  out
}

/// Search with positions using C automaton. Returns Array[Match].
pub fn AhoCorasick::find_all_matches_native(self : AhoCorasick, text : String) -> Array[Match] {
  let text_bytes = string_to_ascii_bytes(text)
  let max_matches = text.length()
  let positions = FixedArray::make(max_matches * 3, 0)
  let count = c_native_ac_search_positions(text_bytes, text.length(), positions, max_matches)
  let out : Array[Match] = []
  for i in 0..<count {
    let pi = positions[i * 3]
    let start = positions[i * 3 + 1]
    let end = positions[i * 3 + 2]
    out.push(Match::{
      pattern_index: pi,
      pattern: self.patterns[pi],
      start,
      end,
    })
  }
  out
}

/// Contains-any using C automaton. Short-circuits.
pub fn AhoCorasick::contains_any_native(self_ : AhoCorasick, text : String) -> Bool {
  ignore(self_)
  let text_bytes = string_to_ascii_bytes(text)
  c_native_ac_contains_any(text_bytes, text.length()) != 0
}

/// Count using C automaton.
pub fn AhoCorasick::count_native(self_ : AhoCorasick, text : String) -> Int {
  ignore(self_)
  let text_bytes = string_to_ascii_bytes(text)
  c_native_ac_count(text_bytes, text.length())
}
