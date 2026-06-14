test "native build + search" {
  let ac = build(["error", "warn", "info"])
  ac.build_native()
  let matches = ac.search_native("error: connection info lost")
  assert_true(matches.contains(0))
  assert_true(matches.contains(2))
}

test "native contains_any" {
  let ac = build(["fatal", "critical"])
  ac.build_native()
  assert_true(ac.contains_any_native("a fatal error"))
  assert_false(ac.contains_any_native("everything is fine"))
}

test "native case insensitive" {
  let ac = build(["hello", "world"])
  ac.build_native()
  let matches = ac.search_native("HELLO beautiful WORLD")
  assert_true(matches.contains(0))
  assert_true(matches.contains(1))
}

test "native count" {
  let ac = build(["ab"])
  ac.build_native()
  assert_eq(ac.count_native("ababab"), 3)
}

test "native find_all_matches_native positions" {
  let ac = build(["cat", "dog"])
  ac.build_native()
  let matches = ac.find_all_matches_native("the cat and the dog")
  assert_eq(matches.length(), 2)
  assert_eq(matches[0].pattern, "cat")
  assert_eq(matches[0].start, 4)
  assert_eq(matches[0].end, 7)
  assert_eq(matches[1].pattern, "dog")
  assert_eq(matches[1].start, 16)
  assert_eq(matches[1].end, 19)
}

test "native overlapping" {
  let ac = build(["ab", "abc", "bc"])
  ac.build_native()
  let matches = ac.search_native("abc")
  assert_eq(matches.length(), 3)
}

test "native many patterns" {
  let patterns = [
    "alpha", "beta", "gamma", "delta", "epsilon",
    "zeta", "eta", "theta", "iota", "kappa",
    "lambda", "mu", "nu", "xi", "omicron",
    "pi", "rho", "sigma", "tau", "upsilon",
  ]
  let ac = build(patterns)
  ac.build_native()
  let found = ac.search_native("alpha to omega, through gamma and theta and sigma")
  assert_true(found.contains(0))
  assert_true(found.contains(2))
  assert_true(found.contains(7))
  assert_true(found.contains(17))
}
