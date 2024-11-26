use std::{borrow::Borrow, collections::HashMap, rc::Rc};

#[derive(Debug, PartialEq, Eq, Clone)]
enum Exp {
    Num(i32),
    Add(Box<Exp>, Box<Exp>),
    Mul(Box<Exp>, Box<Exp>),
    Lam(String, Box<Exp>),
    App(Box<Exp>, Box<Exp>),
    Var(String),
}
use Exp::*;


#[derive(Clone)]
enum Value {
    VNum(i32),
    Clo(Rc<dyn Fn(Rc<Value>) -> Result<Rc<Value>, &'static str>>),
}

#[derive(Clone)]
struct Env {
    func: Rc<dyn Fn(&str) -> Result<Rc<Value>, &'static str>>
}

impl Env {
  fn new(func: Rc<dyn Fn(&str) -> Result<Rc<Value>, &'static str>>) -> Self {
    Self {
      func
    }
  }
}

use Value::*;

fn interp(e: Exp, env: Env) -> Result<Rc<Value>, &'static str> {
    match e {
        Num(n) => Ok(Rc::new(VNum(n))),
        Add(e1, e2) => match (interp(*e1, env.clone())?.borrow(), interp(*e2, env)?.borrow()) {
            (VNum(n1), VNum(n2)) => Ok(Rc::new(VNum(n1 + n2))),
            _ => Err("Adding non-numbers"),
        },
        Mul(e1, e2) => match (interp(*e1, env.clone())?.borrow(), interp(*e2, env)?.borrow()) {
            (VNum(n1), VNum(n2)) => Ok(Rc::new(VNum(n1 * n2))),
            _ => Err("Multiplying non-numbers"),
        },
        Lam(x, body) => {
          let x_copy = x;
          let closure_env = env.clone();
          let body_copy = *body.clone();
          Ok(Rc::new(Clo(Rc::new(move |x_value| {
            let x_copy2 = x_copy.clone();
            let closure_env_copy = closure_env.clone();
            let x_value_copy = x_value.clone();
            let extended_env: Env = Env::new(
              Rc::new(move |id: &str| 
                if x_copy2 == id { 
                  Ok(x_value_copy.clone()) 
                } else { 
                  (closure_env_copy.func)(id)
                }));
            interp(body_copy.clone(), extended_env)
        }))))
      },
        App(e1, e2) => match interp(*e1, env.clone())?.borrow() {
            Clo(f) => f(interp(*e2, env)?),
            _ => Err("Applying non-closure"),
        },
        Var(v) => (env.func)(v.as_str()),
    }
}

fn empty_env(v: &str) -> Result<Rc<Value>, &'static str> {
    Err("Free variable")
}

fn add(e1: Exp, e2: Exp) -> Exp {
    Exp::Add(Box::new(e1), Box::new(e2))
}

fn mul(e1: Exp, e2: Exp) -> Exp {
    Exp::Mul(Box::new(e1), Box::new(e2))
}

fn lam(x: String, e: Exp) -> Exp {
    Exp::Lam(x, Box::new(e))
}

fn app(e1: Exp, e2: Exp) -> Exp {
    Exp::App(Box::new(e1), Box::new(e2))
}

fn var(x: String) -> Exp {
    Exp::Var(x)
}

fn num(n: i32) -> Exp {
    Exp::Num(n)
}

fn main() {
    println!("{:?}", add(num(1), num(2)));
}

impl  Value {
    fn is_closure(&self) -> bool {
        match self {
            Clo(_) => true,
            _ => false,
        }
    }
}

impl  PartialEq for Value {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (VNum(n1), VNum(n2)) => n1 == n2,
            (Clo(_), Clo(_)) => true,
            _ => false,
        }
    }
}

impl  std::fmt::Debug for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> Result<(), std::fmt::Error> {
        match self {
            VNum(n) => write!(f, "VNum({})", n),
            Clo(_) => write!(f, "Clo"),
        }
    }
}

#[test]
fn test() {
    let ee: Env = Env::new(Rc::new(empty_env));
    assert_eq!(*interp(add(num(1), num(2)), ee.clone()).unwrap().to_owned(), VNum(3));
    assert_eq!(*interp(mul(num(2), num(3)), ee.clone()).unwrap().to_owned(), VNum(6));
    assert_eq!(
      *interp(add(mul(num(2), num(3)), num(4)), ee.clone()).unwrap().to_owned(),
        VNum(10)
    );
    assert_eq!(
      interp(lam("x".to_string(), var("x".to_string())), ee.clone())
            .unwrap().to_owned()
            .is_closure(),
        true
    );
    assert_eq!(
      *interp(app(lam("x".to_string(), var("x".to_string())), num(3)), ee.clone()).unwrap().to_owned(),
        VNum(3)
    );
    assert_eq!(
        *interp(
            app(
                lam("x".to_string(), add(var("x".to_string()), num(1))),
                num(3)
            ),
            ee.clone()
        )
        .unwrap().to_owned(),
        VNum(4)
    );
    assert_eq!(
        interp(var("x".to_string()), ee.clone()).unwrap_err(),
        "Free variable"
    );
    assert_eq!(
        interp(app(num(1), num(2)), ee.clone()).unwrap_err(),
        "Applying non-closure"
    );
    assert_eq!(
        interp(add(num(1), lam("x".to_string(), var("x".to_string()))), ee.clone()).unwrap_err(),
        "Adding non-numbers"
    );
    assert_eq!(
        interp(mul(num(1), lam("x".to_string(), var("x".to_string()))), ee).unwrap_err(),
        "Multiplying non-numbers"
    );
}
