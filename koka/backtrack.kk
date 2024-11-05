fun check(a: a, f: () -> <console,exn|e> a, ?(==): (a, a) -> bool, ?kk-file-line: string): <console,exn|e> ()
  println("Checking (" ++ kk-file-line ++ ") ...")
  if f() == a then println("Passed!") else println("Failed!")

effect backtrack
  ctl choose(l: list<a>): a
  ctl guard(b: bool): ()

fun collect(action: () -> <backtrack|e> a): e list<a>
  with handler
    ctl choose(alist)
      alist.flatmap(fn(item) resume(item))
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

fun test-functions()
  check(1)
    with search
    choose([1, 2])

  check(2)
    with search
    val x = choose([1, 2])
    guard(x != 1)
    x
  
  check([2, 3])
    with collect
    val x = choose([1, 2, 3])
    guard(x > 1)
    x

  fun f() 
    choose([1, 2, 3])
  fun g(x) 
    guard(x > 2)
    x
  
  check(3)
    with search
    g(f())