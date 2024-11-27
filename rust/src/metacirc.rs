use std::{borrow::Borrow, collections::HashMap, rc::Rc};

#[derive(Debug, PartialEq, Eq, Clone)]
enum Exp {
    Num(i32),
    Add(Box<Exp>, Box<Exp>),
    Mul(Box<Exp>, Box<Exp>),
    Lam(&'static str, Box<Exp>),
    App(Box<Exp>, Box<Exp>),
    Var(&'static str),
}
use Exp::*;


#[derive(Clone)]
enum Value<'a> where 
{
    VNum(i32),
    Clo(Rc<dyn Fn(Value<'a>) -> Result<Value<'a>, &'static str> + 'a>),
}

impl <'a> Value<'a> {
  fn new_clos(func: impl Fn(Value<'a>) -> Result<Value<'a>, &'static str> + 'a) -> Self {
    Clo(Rc::new(func))
  }
}

#[derive(Clone)]
struct Env<'a>
{
    func: Rc<dyn Fn(&'a str) -> Result<Value<'a>, &'static str> + 'a>
}

impl <'a> Env<'a> {
  fn new(func: impl Fn(&'a str) -> Result<Value<'a>, &'static str> + 'a) -> Self {
    Self {
      func: Rc::new(func)
    }
  }
}

use Value::*;

fn interp<'b>(e: Exp, env: Env<'b>) -> Result<Value<'b>, &'static str>  
{
    match e {
        Num(n) => Ok(VNum(n.clone())),
        Add(e1, e2) => match (interp(*e1, env.clone())?.borrow(), interp(*e2, env)?.borrow()) {
            (VNum(n1), VNum(n2)) => Ok(VNum(n1 + n2)),
            _ => Err("Adding non-numbers"),
        },
        Mul(e1, e2) => match (interp(*e1, env.clone())?.borrow(), interp(*e2, env)?.borrow()) {
            (VNum(n1), VNum(n2)) => Ok(VNum(n1 * n2)),
            _ => Err("Multiplying non-numbers"),
        },
        Lam(x, body) => {
          Ok(Value::new_clos(move |x_value | {
            // The closure environment needs to be cloned each time the function is called
            // since it is used up (moved into the subclosure) at every call
            let closure_env = env.clone(); 
            let extended_env = Env::new(
              move |id| 
                if x == id {
                  // Now the value gets returned (moved out) so we need to clone it, in case this environment gets called again
                  Ok(x_value.clone()) 
                } else { 
                  (closure_env.func)(id)
                });
            // We need to copy the body every time we call the function
            interp(*body.clone(), extended_env)
        }))
      },
        App(e1, e2) => match interp(*e1, env.clone())?.borrow() {
            Clo(f) => f(interp(*e2, env)?),
            _ => Err("Applying non-closure"),
        },
        Var(v) => (env.func)(v),
    }
}

fn add(e1: Exp, e2: Exp) -> Exp {
    Exp::Add(Box::new(e1), Box::new(e2))
}

fn mul(e1: Exp, e2: Exp) -> Exp {
    Exp::Mul(Box::new(e1), Box::new(e2))
}

fn lam(x: &'static str, e: Exp) -> Exp {
    Exp::Lam(x, Box::new(e))
}

fn app(e1: Exp, e2: Exp) -> Exp {
    Exp::App(Box::new(e1), Box::new(e2))
}

fn var(x: &'static str) -> Exp {
    Exp::Var(x)
}

fn num(n: i32) -> Exp {
    Exp::Num(n)
}

fn main() {
    println!("{:?}", add(num(1), num(2)));
}

impl  <'a> Value<'a> {
    fn is_closure(&self) -> bool {
        match self {
            Clo(_) => true,
            _ => false,
        }
    }
}

impl <'a> PartialEq for Value<'a> {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (VNum(n1), VNum(n2)) => n1 == n2,
            (Clo(_), Clo(_)) => true,
            _ => false,
        }
    }
}

impl <'a> std::fmt::Debug for Value<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> Result<(), std::fmt::Error> {
        match self {
            VNum(n) => write!(f, "VNum({})", n),
            Clo(_) => write!(f, "Clo"),
        }
    }
}

fn interp_top<'a>(exp : Exp) -> Result<Value<'a>, &'static str> {
  interp(exp, Env::new(|_x| Err("Free variable")))
}

#[test]
fn test() {
    assert_eq!(interp_top(add(num(1), num(2))).unwrap().to_owned(), VNum(3));
    assert_eq!(interp_top(mul(num(2), num(3))).unwrap().to_owned(), VNum(6));
    assert_eq!(
      interp_top(add(mul(num(2), num(3)), num(4))).unwrap().to_owned(),
        VNum(10)
    );
    assert_eq!(
      interp_top(lam("x", var("x")))
            .unwrap().to_owned()
            .is_closure(),
        true
    );
    assert_eq!(
      interp_top(app(lam("x", var("x")), num(3))).unwrap().to_owned(),
        VNum(3)
    );
    assert_eq!(
      interp_top(
          app(
              lam("x", add(var("x"), num(1))),
              num(3)
            )
        )
        .unwrap().to_owned(),
        VNum(4)
    );
    assert_eq!(
      interp_top(var("x")).unwrap_err(),
        "Free variable"
    );
    assert_eq!(
      interp_top(app(num(1), num(2))).unwrap_err(),
        "Applying non-closure"
    );
    assert_eq!(
      interp_top(add(num(1), lam("x", var("x")))).unwrap_err(),
        "Adding non-numbers"
    );
    assert_eq!(
      interp_top(mul(num(1), lam("x", var("x")))).unwrap_err(),
        "Multiplying non-numbers"
    );
}
