import std/text/parse
import std/core/undiv

fun check(expected: a, f: () -> <console,pure|e> a, ?(==): (a, a) -> div bool, ?kk-file-line: string): <console,div|e> ()
  println("Checking (" ++ kk-file-line ++ ") ...")
  match try(f)
    Error(e) -> println("Failed! " ++ e.message)
    Ok(actual) -> if actual == expected then println("Passed!") else println("Failed!") 

fun check-exn(expected-err: string, f: () -> <console,exn|e> a, ?kk-file-line: string): <console|e> ()
  println("Checking exception (" ++ kk-file-line ++ ") ...")
  match try(f)
    Error(e) -> if expected-err == e.message then println("Passed!") else println("Failed!")
    _ -> println("Failed!")

type json
  JSNull
  JSBool(b : bool)
  JSNum(n : int)
  JSString(s : string)
  JSArray(arr : list<json>)
  JSObject(entries : list<(string, json)>)

fun json/(==)(j1: json, j2: json): bool
  match (j1, j2)
    (JSNull, JSNull) -> True
    (JSBool(b1), JSBool(b2)) -> b1 == b2
    (JSNum(n1), JSNum(n2)) -> n1 == n2
    (JSString(s1), JSString(s2)) -> s1 == s2
    (JSArray(a1), JSArray(a2)) -> (==)(a1, a2, ?(==) = fn(e1, e2) e1.pretend-decreasing == e2)
    (JSObject(a1), JSObject(a2)) -> 
      a1.length == a2.length &&
      a1.all(fn((k1, v1)) a2.any(fn((k2, v2)) k1 == k2 && (==)(v1.pretend-decreasing, v2)))
    _ -> False

fun token_parser(p)
  many({char-is("whitespace", fn(c) c == ' ' || c == '\t' || c == '\n')})
  p()

fun pquotedstring()
  char('"'); 
  val chars = pstringchars(); 
  char('"');
  chars.string

fun pstringchars()
  with many
  satisfy-fail("String character") fn(slice)
    match slice.next
      Nothing -> Nothing
      Just((c, nslice)) -> 
        if c == '"' then Nothing
        elif c == '\\' then
          match nslice.next
            Nothing -> Nothing
            Just(('\\', next)) -> Just(('\\',next))
            Just(('r', next)) -> Just(('\r',next))
            Just(('n', next)) -> Just(('\n',next))
            Just(('"', next)) -> Just(('"',next))
            Just((_, _)) -> Nothing
        else Just((c, nslice))

fun pdelimited(valueparser, separatorparser)
  val maybev = optional(Nothing) 
                  Just(valueparser())
  match maybev
    Nothing ->  []
    Just(v) -> 
      optional([v]) 
        token_parser({separatorparser()})
        Cons(v, pdelimited(valueparser, separatorparser))

fun pjson()
  token_parser
    choose([
      // TODO: Fill in all the alternatives for json grammar parsing
    ])

fun parse_json(s : string): <pure> json
  match parse(s.slice, {val j = pjson(); eof(); j})
    ParseOk(j) -> j
    ParseError(e) -> throw("Failed to parse JSON: " ++ e)

fun test()
  check(JSNull)
    parse_json(" null")
  check(JSObject([("a", JSNum(1)), ("b", JSNum(2))]))
    parse_json(r#" { "a" : 1, "b" : 2 }"#)
  check(JSArray([JSNum(1), JSNum(2), JSNum(3)]))
    parse_json(" [ 1 , 2, 3 ]")
  