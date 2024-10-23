-- [Type] is the syntax for a list of Type.
-- This is a function that takes in an int, and returns a function that takes in a list of ints and returns a list of ints.
-- Haskell, like many functional languages, is curried - meaning that functions by default only take one argument at a time (though you can explicitly require a tuple argument).
-- Because of this parameter lists don't make sense (since they would always only have one argument).
--   To remove unnecessary parentheses, Haskell uses a function call syntax where you put arguments separated by spaces after the function you want to call
--   To define a function you put the argument names separated by spaces after the function name and before the equals sign
mult :: Int -> [Int] -> [Int]
mult n l = map (\x -> x * n) l -- This calls map with a lambda function (taking in the parameter `x` with body `x * n`) and the list `l`, mapping the lambda function over the list.

-- Because of currying, you can partially apply functions, (meaning only supply one parameter and get a function that takes the rest of the parameters)
-- For example in the following function we have partially applied multiplication `*` to `2`, which results in a function that takes in another int and multiplies it by 2.
{-
>>> (* 2) 3
6
-}
-- We have then called that function with the last missing parameter (3) to get the result 6.
-- The following is `mult` rewritten to use partial application
mult2 :: Int -> [Int] -> [Int]
mult2 n l = map (* n) l
{-
>>> mult2 4 [1,2,3]
[4,8,12]
-}

-- Uncomment the following two lines of code to give a function definition for the double function, which doubles all elements in the list 
-- Then use `mult` from above to implement double.
double :: [Int] -> [Int]
double = mult 2

-- Next click evaluate in the following comment (leave it commented) to run the code and make sure it works.
-- You will need the Haskell language server and the VSCode extension installed for this to work.
{-
>>> double [1,2,3]
[2,4,6]

// Expected: [2,4,6]
-}

-- Now let's take a look at pattern matching, lists, and booleans.
-- Booleans in Haskell are just variant constructors for the type Bool. They are `True` and `False`. Remember you don't need parentheses to call constructors!
-- Lists are constructed using `[1, 2, 3]` literals, or `:` (cons) and `[]` (nil) constructors (i.e. `1:2:[]`).
-- To match on variants you use the `case of ...` syntax. You still use the variant constructors and literals to match on data like Shplait, but with spaces instead of parentheses!
-- Because Haskell is a real functional language it implements nested matching. In other words, you can match on the first two elements and rest instead of just the first and rest of a list.
-- Also for lists you use the `:` constructor to match on the start and rest of the list.
-- Fill in the rest of this definition of stutter, which takes a list and returns `True` if the list has two consecutive elements that are the same.
stutter :: [Int] -> Bool
stutter l = 
    case l of
        [] -> False
        x:[] -> False
        x:y:xs -> x == y || stutter (y:xs)

{-
>>> stutter [1,2,3,4,5]
False

// Expected: False

>>> stutter [1,2,3,4,4,5]
True

// Expected: True
-}


-- To create a new type in Haskell you use the `data` keyword. This is similar to the `type` keyword in Shplait. Constructor arguments don't need names, just types in spaced lists.
-- Often you will have unnamed arguments in constructors - since you mostly use them in pattern matching. There are ways to give names to them though.
-- This is the syntax for a simple expression language with integers, booleans, addition, multiplication, and if statements.
data Exp = I !Int
         | B !Bool
         | Add !Exp !Exp
         | Mul !Exp !Exp
         | If !Exp !Exp !Exp
         deriving (Show,Eq) -- We derive `Show` which allows us to print a representation of this type to the console, and `Eq` which allows us to compare values of this type for equality.

data Val = IV !Int
         | BV !Bool
         deriving (Show,Eq)

-- Using what you know now about pattern matching and variants fill in the following definition for `eval` which evaluates an expression to a value.
-- This is a basic calculator language with if, so you don't need environments or anything like that. 
-- For errors call `error "message"` to throw an error with the given message. 
-- For int operations, throw an error including "Expected num" if the value is not an integer.
-- For the if condition, throw an error including "Expected bool" if the value is not an boolean value.

-- Evaluates the language above:
-- Hint: case of expression is pattern matching
eval :: Exp -> Val
eval exp = 
   case exp of
     I n -> IV n
     B b -> BV b
     Add r l -> 
       case (eval r, eval l) of
         (IV n1, IV n2) -> IV (n1 + n2)
         _ -> error "Expected num"
     Mul r l ->
         case (eval r, eval l) of
            (IV n1, IV n2) -> IV (n1 * n2)
            _ -> error "Expected num"
     If c t f ->
        case eval c of
            BV b -> if b then eval t else eval f
            _ -> error "Expected bool"
-- Here are a few tests you can run to make sure you implemented `eval` correctly.
{-
>>> eval (Add (I 1) (I 2))
IV 3

// Expect: IV 3

>>> eval (If (B True) (I 1) (I 2))
IV 1

// Expect: IV 1

>>> eval (If (B False) (I 1) (I 2))
IV 2

// Expect: IV 2

>>> eval (Mul (I 2) (I 3))
IV 6

// Expect: IV 6
-}


-- Now let's take advantage of Haskell's laziness and infinite lists to implement some recursive data structures.
-- This is definitely something new! Because Haskell is lazy, you can define infinite lists and use them in your programs, as long as you don't try to evaluate the whole list - because then you would get stuck.

-- Examples from the assignment description (read the description before moving on if you haven't already, it's important!):
naturals :: [Int]
naturals = 1:map (+1) naturals
doubles :: [Int]
doubles = zipWith (+) naturals naturals
squares :: [Int]
squares = zipWith (*) naturals naturals
{-
>>> take 5 naturals
[1,2,3,4,5]
>>> take 5 doubles
[2,4,6,8,10]
>>> take 5 squares
[1,4,9,16,25]
-}


-- Now let's implement factorial with lazy lists.
-- factorial :: [Int]
-- factorial = ....

{-
>>> take 5 factorial -- This test will attempt to get the first 5 elements of the factorial list. Don't hard-code this list, since we will be testing with different lists.

// Expected: [1,1,2,6,24,120]
-}


-- Implement the fibonacci sequence with lazy lists
-- fibonacci :: [Int]
-- fibonacci = ....

{-
>>> take 6 fibonacci -- This test will attempt to get the first 5 elements of the fibonacci list. Don't hard-code this list, since we will be testing with different lists.

// Expected: [0,1,1,2,3,5]
-}



