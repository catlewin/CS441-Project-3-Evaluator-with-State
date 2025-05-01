# Racket Expression Evaluator

_A functional interpreter with state management_

_____

## Features
✔ Arithmetic operations (add, sub, mult, div or +, -, *, /)

✔ Variable management: define, assign, remove, id

✔ Immutable state propagation

✔ Detailed error handling ((failure "Error message"))

## How It Works

The evaluator:
1. Parses expressions like (add (num 2) (id x)
2. Tracks variables in an immutable state (e.g., ((x . 5) (y . 10)))
3. Returns (success value) or (failure "msg")

_Example Session:_

      > (define x (num 5))  
        Result: (success 5)  
        State: ((x . 5))  
        
      > (add (id x) (num 3))  
        Result: (success 8)  
        State: ((x . 5))  

## Credits

Developed as a learning project with guidance from DeepSeek. Prompts & logs below.
