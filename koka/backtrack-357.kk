fun check(a: a, f: () -> <console,exn|e> a, ?(==): (a, a) -> bool, ?kk-file-line: string): <console,exn|e> ()
  println("Checking (" ++ kk-file-line ++ ") ...")
  if f() == a then println("Passed!") else println("Failed!")

effect backtrack
  ctl choose(l: list<a>): a
  ctl guard(b: bool): ()

fun collect(action: () -> <backtrack|e> a): e list<a>
  with handler
    ctl choose(alist)
      alist.map(fn(item) resume(item)).concat
    ctl guard(condition)
      if condition then resume(()) else []
    return(result)
      [result]
  action()

fun search(action: () -> <backtrack,exn|e> a, ?kk-file-line: string): <exn|e> a
  match search-maybe(action)
    Just(result) -> result
    Nothing -> throw("Search found nothing!" ++ kk-file-line)

fun search-maybe(action: () -> <backtrack|e> a): e maybe<a>
  with handler
    ctl choose(alist)
      fun try(lst)
        match lst
          Nil -> Nothing
          Cons(first, rest) ->
            match resume(first)
              Just(result) -> Just(result)
              Nothing -> try(rest)
      try(alist) 
    ctl guard(condition)
      if condition then resume(()) else Nothing
    return(result)
      Just(result)
  action()

/// Problem 357: Counting numbers with unique digits if the number has n digits

fun all_unique(n : int)
  val x = collect(fn(){ n_unique(n, n) })
  x.length

// Strategy 1: Recursively generate all possible combinations of n digits in a list
fun n_unique(n : int, ns: int)
  if n == 0 then Nil // Take care of base case
  else 
    // Recur on the rest
    val rest = n_unique(n - 1, ns) 
    // If this isn't the first digit or there is only 1 digit total we can choose 0, otherwise we can't
    val options = if n != ns || ns == 1 then [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]  else [1, 2, 3, 4, 5, 6, 7, 8, 9]
    // Choose one of our options (all of them one by one)
    val x = choose(options) 
    // If the one we chose is already in the rest, we can't choose it (terminate this computation)
    guard(!rest.any(fn(y) y == x)) 
    // Otherwise we can choose it and add it to the rest
    Cons(x, rest) 

fun test-v1()
  all_unique(1).println
  all_unique(2).println
  all_unique(3).println

fun all_unique1_5(n : int)
  val x = collect(fn(){ n_unique1_5(n, n) })
  x.length

// Strategy 1.5: Recursively generate all possible combinations of n digits in a list
fun n_unique1_5(n : int, ns: int)
  if n == 0 then Nil // Take care of base case
  else 
    // Recur on the rest
    val rest = n_unique1_5(n - 1, ns) 
    // Choose one of our options (all of them one by one)
    val x = choose([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) 
    // If this isn't the first digit or there is only 1 digit total we can choose 0, otherwise we can't
    guard(x != 0 || ns == 1 || ns != n)
    // If the one we chose is already in the rest, we can't choose it (terminate this computation)
    guard(!rest.any(fn(y) y == x)) 
    // Otherwise we can choose it and add it to the rest
    Cons(x, rest) 


fun test-v1_5()
  all_unique1_5(1).println
  all_unique1_5(2).println
  all_unique1_5(3).println
  

fun all_unique2(n : int)
  collect(fn(){ n_unique2(n, n, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) }).length

// Strategy 2: Remove from the list as we use up a digit
fun n_unique2(n : int, ns: int, l: list<int>)
  if n == 0 then Nil // Take care of base case
  else 
    // If this isn't the first digit or there is only 1 digit total we can choose 0, otherwise we can't
    val x = choose(l) 
    // We can choose zero if it's the first digit or there is only one digit total otherwise we can't 
    guard(ns != n || ns == 1 || x != 0)
    // When recurring, remove the digit we are using from the list
    val rest = n_unique2(n - 1, ns, l.filter(fn(y) y != x)) 
    Cons(x, rest)

fun test-v2()
  all_unique2(1).println
  all_unique2(2).println
  all_unique2(3).println

// Strategy 3: Do the math (not a backtracking approach)
fun all_combinations(n : int)
  if n == 0 then 0 // 0 combinations of 0 digits
  elif n == 1 then 10 // 10 combinations if only one digit
  // Otherwise 9 combinations for the first digit (no zero) 
  // and we start with 9 options for the second digit (no repeats but can use zero now)
  else 9 * combinations(n - 1, 9) 
  
fun combinations(n: int, current: int)
  if n == 0 then 1 // 1 combination of 0 digits
  // Otherwise current * combinations of n - 1 digits with current - 1 options
  else current * combinations(n - 1, current - 1) 

fun test-v3()
  all_combinations(1).println
  all_combinations(2).println
  all_combinations(3).println