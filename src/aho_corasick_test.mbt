test "basic search" {
  let ac = build(["they", "them", "their", "theirs"])
  let matches = ac.search("they gave them their things and kept theirs")
  assert_true(matches.contains(0))
  assert_true(matches.contains(1))
  assert_true(matches.contains(2))
  assert_true(matches.contains(3))
}

test "find_all returns strings" {
  let ac = build(["valence", "moonbit", "helios"])
  let found = ac.find_all("building valence in moonbit for helios")
  assert_true(found.contains("valence"))
  assert_true(found.contains("moonbit"))
  assert_true(found.contains("helios"))
  assert_eq(found.length(), 3)
}

test "contains_any short-circuits" {
  let ac = build(["error", "warning", "fatal"])
  assert_true(ac.contains_any("this has an error in it"))
  assert_true(ac.contains_any("warning: something"))
  assert_false(ac.contains_any("all clear nothing here"))
}

test "no match returns empty" {
  let ac = build(["cat", "dog"])
  let matches = ac.search("bird fish")
  assert_eq(matches.length(), 0)
  assert_false(ac.contains_any("bird fish"))
}

test "overlapping patterns" {
  let ac = build(["ab", "abc", "bc"])
  let found = ac.find_all("abc")
  assert_true(found.contains("ab"))
  assert_true(found.contains("abc"))
  assert_true(found.contains("bc"))
}

test "single character patterns" {
  let ac = build(["a", "b", "c"])
  let found = ac.find_all("abcabc")
  assert_eq(found.length(), 3)
}

test "unicode patterns" {
  let ac = build(["привет", "мир"])
  assert_true(ac.contains_any("привет мир"))
  assert_false(ac.contains_any("hello world"))
}

test "empty text" {
  let ac = build(["hello"])
  assert_false(ac.contains_any(""))
  assert_eq(ac.search("").length(), 0)
}

test "pattern at boundaries" {
  let ac = build(["start", "end"])
  assert_true(ac.contains_any("start of text"))
  assert_true(ac.contains_any("the end"))
  assert_true(ac.contains_any("startend"))
}

test "state and pattern counts" {
  let ac = build(["ab", "abc", "bc"])
  assert_eq(ac.pattern_count(), 3)
  assert_true(ac.state_count() > 1)
}

test "case sensitive by default" {
  let ac = build(["hello"])
  assert_true(ac.contains_any("hello"))
  assert_false(ac.contains_any("Hello"))
}

test "case insensitive via lowering" {
  let ac = build(["hello", "world"])
  let text = "Hello Beautiful WORLD".to_lower()
  let found = ac.find_all(text)
  assert_true(found.contains("hello"))
  assert_true(found.contains("world"))
}

test "search_bytes basic" {
  let ac = build(["cat", "dog"])
  let text : Bytes = b"the cat sat on the dog"
  let matches = ac.search_bytes(text, text.length())
  assert_eq(matches.length(), 2)
}

test "contains_any_bytes" {
  let ac = build(["error", "warn"])
  assert_true(ac.contains_any_bytes(b"an error occurred", 17))
  assert_false(ac.contains_any_bytes(b"all good", 8))
}

test "search_bytes no match" {
  let ac = build(["xyz"])
  let matches = ac.search_bytes(b"abcdef", 6)
  assert_eq(matches.length(), 0)
}

test "many patterns" {
  let patterns = [
    "alpha", "beta", "gamma", "delta", "epsilon",
    "zeta", "eta", "theta", "iota", "kappa",
  ]
  let ac = build(patterns)
  let found = ac.find_all("alpha to omega, passing through gamma and theta")
  assert_true(found.contains("alpha"))
  assert_true(found.contains("gamma"))
  assert_true(found.contains("theta"))
  assert_false(found.contains("omega"))
}
