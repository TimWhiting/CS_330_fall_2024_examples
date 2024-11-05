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

fun interp(e: exp, env: env): <exn,div> evalue // TODO: change the effect to <div,store,error>
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
    EBox(startval) -> throw("TODO: Implement this")
    ESetBox(box, newval) -> throw("TODO: Implement this")
    EGetBox(box) -> throw("TODO: Implement this")
    EThrow(s: string) -> throw("TODO: Implement this")
    ECatch(s: string, handl: exp, body: exp) ->
      // This one is a bit tricky, so let me give you a bit of help
      // with override // override the error effect
      //   ctl ethrow(s)
      //     throw("TODO: Implement this")
      throw("TODO: Implement this (and uncomment the above)")


fun real-interp(e: exp): <exn,div> err<evalue> // TODO: after changing the interpreter effect - when changing throw to use ethrow, also change `exn,div` here to `div`
  var store : list<(location, evalue)> := []
  with handler
    fun store-get(l: location)
      throw("TODO: Implement this")
    fun store-add(v: evalue)
      throw("TODO: Implement this")
    fun store-update(l: location, v: evalue)
      throw("TODO: Implement this")
  with handler
    final ctl ethrow(s: string)
      throw("TODO: Implement this")
    return(x)
      throw("TODO: Implement this")
  interp(e, [])

// Some sugar to build expressions without using the constructors
fun ident/lam(x: identifier, exp: (exp) -> e exp): e exp
  ELam(x, exp(x.ident))

fun simple/lam(x: identifier, exp: () -> e exp): e exp
  ELam(x, exp())

fun (:->)(x: identifier, body: exp): exp
  lam(x)
    body

fun app(func: exp, arg: exp): exp
  EApp(func, arg) // Unfortunately there isn't a good way to overload the `()` operator

fun (+)(left: exp, right: exp): exp
  EAdd(left, right) // Overload the + operator for expressions

fun (*)(left: exp, right: exp): exp
  EMult(left, right) // Overload the * operator for expressions

fun box(startval: exp): exp
  EBox(startval)

fun set-box(box: exp, newval: exp): exp
  ESetBox(box, newval)

fun get-box(box: exp): exp
  EGetBox(box)

fun begin(first: exp, next: () -> e exp): e exp
  EBegin(first, next())

fun ident(s: string): exp
  EVar(s)

fun num(n: int): exp
  ENum(n)

// Desugars let to application.
// `body` is a function that takes in the identifier and constructs the body expression
fun let(x: identifier, value: exp, body: (exp) -> e exp): e exp
  app(x :-> body(x.ident), value)

fun test()
  check(VNum(2))
    real-interp(1.num + 2.num)
  check-exn("Free variable")
    real-interp("x".ident)
  check(VNum(2))
    real-interp(set-box(box(1.num), 2.num))
  
  val example = 
        with b <- let("b", box(1.num))
        begin(set-box(b, 2.num)) 
          get-box(b)
  println(real-interp(example)) // should print Good(2)