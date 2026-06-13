test "basic search" {
  let ac = build(["he", "she", "his", "hers"])
  let matches = ac.search("ushers")
  assert_true(matches.contains(0))
  assert_true(matches.contains(1))
  assert_true(matches.contains(3))
}

test "find_all returns strings" {
  let ac = build(["hello", "world"])
  let found = ac.find_all("hello beautiful world")
  assert_true(found.contains("hello"))
  assert_true(found.contains("world"))
  assert_eq(found.length(), 2)
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
  assert_false(ac.contains_any("HELLO"))
}

test "case insensitive via lowering" {
  let patterns = ["hello", "world"]
  let ac = build(patterns)
  let text = "Hello Beautiful WORLD".to_lower()
  let found = ac.find_all(text)
  assert_true(found.contains("hello"))
  assert_true(found.contains("world"))
}
