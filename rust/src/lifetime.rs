use std::collections::HashMap;
#[derive(Debug, PartialEq, Eq, Clone)]
pub enum Exp {
    Num(i32),
    Add(Box<Exp>, Box<Exp>),
    Mul(Box<Exp>, Box<Exp>),
    Lam(String, Box<Exp>),
    App(Box<Exp>, Box<Exp>),
    Var(String)
}

use Exp::*;

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum Value<'a> {
    Num(i32),
    Clo(&'a str, &'a Exp, HashMap<&'a str, Value<'a>>)
}

pub fn interp<'a, 'b>(e : &'a Exp, env : &HashMap<&'a str, Value<'a>>) -> Result<Value<'a>, &'static str> {
  match e {
    Num(n) => Ok(Value::Num(*n)),
    Add(e1, e2) => 
      match (interp(e1, env)?, interp(e2, env)?){
        (Value::Num(n1), Value::Num(n2)) => Ok(Value::Num(n1+n2)),
        _ => Err("Adding non-numbers")
      }
    Mul(e1, e2) => 
      match (interp(e1, env)?, interp(e2, env)?){
        (Value::Num(n1), Value::Num(n2)) => Ok(Value::Num(n1*n2)),
        _ => Err("Multiplying non-numbers")
      },
    Lam(s, e2) => Ok(Value::Clo(s,e2,env.clone())),
    App(e1, e2) => 
    match interp(e1, env)? {
      Value::Num(_) => Err("Applying non-closure"),
      Value::Clo(x, b, cenv) => {
        let mut new_env = cenv;
        new_env.insert(x, interp(e2,env)?);
        interp(b, &new_env)
      }
    }
      ,
    Var(v) => 
      match env.get(v.as_str()) {
        Some(n) => Ok(n.clone()),
        None => Err("Free variable")
      }
  }
}

pub fn add(e1 : Exp, e2 : Exp) -> Exp {
    Add(Box::new(e1), Box::new(e2))
}

pub fn mul(e1 : Exp, e2 : Exp) -> Exp {
    Mul(Box::new(e1), Box::new(e2))
}

pub fn lam(x : String, e : Exp) -> Exp {
    Lam(x, Box::new(e))
}

pub fn app(e1 : Exp, e2 : Exp) -> Exp {
    App(Box::new(e1), Box::new(e2))
}

pub fn var(x : String) -> Exp {
    Var(x)
}

pub fn num(n : i32) -> Exp {
    Num(n)
}

#[test]
fn test()
{
    assert_eq!(interp(&add(num(1), num(2)), &HashMap::new()).unwrap(), Value::Num(3));
    assert_eq!(interp(&mul(num(2), num(3)), &HashMap::new()).unwrap(), Value::Num(6));
    assert_eq!(interp(&add(mul(num(2), num(3)), num(4)), &HashMap::new()).unwrap(), Value::Num(10));
    assert_eq!(interp(&lam("x".to_string(), var("x".to_string())), &HashMap::new()).unwrap(), Value::Clo("x", &var("x".to_string()), HashMap::new()));
    assert_eq!(interp(&app(lam("x".to_string(), var("x".to_string())), num(3)), &HashMap::new()).unwrap(), Value::Num(3));
    assert_eq!(interp(&app(lam("x".to_string(), add(var("x".to_string()), num(1))), num(3)), &HashMap::new()).unwrap(), Value::Num(4));
    assert_eq!(interp(&var("x".to_string()), &HashMap::new()).unwrap_err(), "Free variable");
    assert_eq!(interp(&app(num(1), num(2)), &HashMap::new()).unwrap_err(), "Applying non-closure");
    assert_eq!(interp(&add(num(1), lam("x".to_string(), var("x".to_string()))), &HashMap::new()).unwrap_err(), "Adding non-numbers");
    assert_eq!(interp(&mul(num(1), lam("x".to_string(), var("x".to_string()))), &HashMap::new()).unwrap_err(), "Multiplying non-numbers");
}