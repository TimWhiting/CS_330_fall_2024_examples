fun check(expected: a, f: () -> <console,pure|e> err<a>, ?(==): (a, a) -> exn bool, ?kk-file-line: string): <console,pure|e> ()
  println("Checking (" ++ kk-file-line ++ ") ...")
  match f() 
    Good(actual) -> if actual == expected then println("Passed!") else println("Failed!")
    _ -> println("Failed!")

fun check-exn(expected-err: string, f: () -> <console|e> err<a>, ?kk-file-line: string): <console|e> ()
  println("Checking exception (" ++ kk-file-line ++ ") ...")
  match f()
    Err(actual) -> if expected-err == actual then println("Passed!") else println("Failed!")
    _ -> println("Failed!")

value type err<a>
  Good(a: a)
  Err(string: string)

fun err/(==)(x: err<a>, y: err<a>, ?(==): (a, a) -> e bool): e bool
  match (x, y)
    (Good(a1), Good(a2)) -> a1 == a2
    (Err(s1), Err(s2)) -> s1 == s2
    _ -> False

fun err/show(x: err<a>, ?show: (a) -> e string): e string
  match x
    Good(v) -> "Good(" ++ v.show ++ ")"
    Err(s) -> "Err(" ++ s ++ ")"

alias location = int
alias identifier = string

type exp
  EAdd(left: exp, right: exp)
  EMult(left: exp, right: exp)
  ENum(n: int)
  EVar(id: identifier)
  ELam(id: identifier, body: exp)
  EApp(func: exp, arg: exp)
  ESetBox(box: exp, newval: exp)
  EGetBox(box: exp)
  EBox(startval: exp)
  EBegin(first : exp, next: exp)
  EThrow(s: string)
  ECatch(s: string, handl: exp, body: exp)

type evalue
  VNum(n: int)
  VBox(v: location)
  VClosure(id: identifier, body: exp, env: env)

fun evalue/(==)(x: evalue, y: evalue): exn bool
  match (x, y)
    (VNum(n1), VNum(n2)) -> n1 == n2
    (VBox(l1), VBox(l2)) -> l1 == l2
    (VClosure, VClosure) -> throw("Uncomparable")
    _ -> False

fun evalue/show(x: evalue): string
  match x
    VNum(n) -> n.show
    VBox(l) -> "Box(" ++ l.show ++ ")"
    VClosure -> "closure"

alias env = list<(identifier, evalue)>

effect store
  fun store-get(l: location): maybe<evalue>
  fun store-add(v: evalue): location
  fun store-update(l: location, v: evalue): maybe<()>

effect error
  ctl ethrow(s: string): a

fun get(list: list<(a,b)>, v: a, ?(==): (a, a) -> bool): maybe<b>
  list.lookup(fn(i) i == v)

fun update(store: list<(location, evalue)>, l: location, vnew: evalue): maybe<list<(location, evalue)>>
  match store
    Nil -> Nothing
    Cons((loc, v), rest) ->
      if loc == l then Just(Cons((loc, vnew), rest))
      else 
        match update(rest, l, v)
          Just(rest') -> Just(Cons((loc, v), rest'))
          Nothing -> Nothing

fun interp(e: exp, env: env): <error,exn,div,store> evalue // TODO: change the effect to <div,store,error>
  match e
    ENum(n) -> VNum(n)
    EVar(ident) -> 
      match env.get(ident)
        Just(v) -> v
        Nothing -> throw("Free variable")
    EAdd(left, right) -> 
      match (interp(left, env), interp(right, env))
        (VNum(n1), VNum(n2)) -> VNum(n1 + n2)
        _ -> throw("Addition of non-numbers")
    EMult(left, right) ->
      match (interp(left, env), interp(right, env))
        (VNum(n1), VNum(n2)) -> VNum(n1 * n2)
        _ -> throw("Multiplication of non-numbers")
    ELam(ident, body) -> VClosure(ident, body, env)
    EApp(func, arg) -> 
      match interp(func, env)
        VClosure(id, body, fenv) -> interp(body, Cons((id, interp(arg, env)), fenv))
        _ -> throw("Application of non-function")
    EBegin(first, next) ->
      interp(first, env)
      interp(next, env)
    EBox(startval) -> throw("TODO: Implement this")
    ESetBox(box, newval) -> throw("TODO: Implement this")
    EGetBox(box) -> 
      match interp(box, env)
        VBox(loc) -> 
          match store-get(loc)
            Just(v) ->  v
            Nothing -> ethrow("location not found")
        _ -> ethrow("not a box") 
    EThrow(s: string) -> ethrow(s)
    ECatch(s: string, handl: exp, body: exp) ->
      // This one is a bit tricky, so let me give you a bit of help
      with override // override the error effect
        ctl ethrow(errors)
          if errors == s then
            interp(handl, env)
          else
            ethrow(errors)
      interp(body, env)

fun real-interp(e: exp): <exn,div> err<evalue> // TODO: after changing the interpreter effect - when changing throw to use ethrow, also change `exn,div` here to `div`
  var store : list<(location, evalue)> := []
  with handler
    fun store-get(l: location)
      store.get(l)
    fun store-add(v: evalue)
      val newloc = store.length
      store := Cons((newloc,v), store)
      newloc
    fun store-update(l: location, v: evalue)
      match store.update(l, v)
        Just(st') -> 
          store := st'
          Just(())
        Nothing -> Nothing
  with handler
    final ctl ethrow(s: string)
      Err(s)
    return(x)
      Good(x)
  interp(e, [])

// Desugars let to application.
// `body` is a function that takes in the identifier and constructs the body expression
fun let(x: identifier, value: exp, body: exp): e exp
  EApp(ELam(x, body), value)

fun test()
  check(VNum(2))
    real-interp(EAdd(ENum(1), ENum(2)))
  check-exn("Free variable")
    real-interp(EVar("x"))
  check(VNum(2))
    real-interp(ESetBox(EBox(ENum(1)), ENum(2)))
  
  val example = 
        let("b", EBox(ENum(1)), 
            EBegin(ESetBox(EVar("b"), ENum(2)), 
                   EGetBox(EVar("b"))))
        
  println(real-interp(example)) // should print Good(2)