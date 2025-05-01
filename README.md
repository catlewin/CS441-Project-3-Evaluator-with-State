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

**Prompt 1 (Initial Guidance)**

CatL: Hey DeepSeek! Can you break down the steps of this assignment [Assignment details attached...]

DeepSeek Response: 
1. Convert Maybe to Either/Result types  
2. Implement variable state management  
3. Build a REPL with immutable state updates  

Key challenges:  
- Propagating state through nested evaluations  
- Handling errors without mutable variables

            #lang racket

            ; Define our success/failure constructors and accessors
            (define (success x) (list 'success x))
            (define (failure msg) (list 'failure msg))
            (define (success? x) (equal? (first x) 'success))
            (define (failure? x) (equal? (first x) 'failure))
            (define (from-success default x)
              (if (success? x) (second x) default))
            (define (from-failure default x)
              (if (failure? x) (second x) default))
            
            (define (safe-div x y)  ; num num -> either num
              (if (= y 0)
                  (failure "Division by zero")
                  (success (/ x y))))
            
            (define in-list?   ; item list -> bool 
              (λ (x lst)
                (not (false? (member x lst)))))
            ; State management functions
            (define (get-var state name)
              (let ([result (assoc name state)])
                (if result (cdr result) 'undefined)))
            
            (define (add-var state name value)
              (if (assoc name state)
                  (values #f state) ; variable exists, return unchanged
                  (values #t (cons (cons name value) state))))
            
            (define (update-var state name value)
              (if (assoc name state)
                  (values #t (map (λ (pair) 
                                   (if (equal? (car pair) name) 
                                       (cons name value) 
                                       pair))
                                 state))
                  (values #f state))) ; variable doesn't exist
            
            (define (remove-var state name)
              (filter (λ (pair) (not (equal? (car pair) name))) state))
            
            ; Extend the evaluator to handle variables and commands
            (define (eval expr state)
              (match expr
                [(list 'num n) (values (success n) state)]
                [(list 'id name) 
                 (let ([val (get-var state name)])
                   (if (equal? val 'undefined)
                       (values (failure (format "Undefined variable: ~a" name)) state)
                       (values (success val) state)))]
                [(list 'define name) 
                 (let-values ([(success? new-state) (add-var state name 'undefined)])
                   (if success?
                       (values (success 'undefined) new-state)
                       (values (failure (format "Variable already defined: ~a" name)) state)))]
                [(list 'define name value-expr)
                 (let-values ([(val new-state1) (eval value-expr state)])
                   (if (failure? val)
                       (values val state)
                       (let ([value (from-success #f val)])
                         (let-values ([(success? new-state2) (add-var new-state1 name value)])
                           (if success?
                               (values (success value) new-state2)
                               (values (failure (format "Variable already defined: ~a" name)) state))))))]
                [(list 'assign name value-expr)]))

**Prompt 2 (Debugging)**

CatL: I’m getting "op: unbound identifier in: op" in the arithmetic operations section. Here’s my code: [code snippet]

DeepSeek Response: 

            ; Fixed pattern matching for arithmetic ops:
            [(list op args ...)  
             (cond  
               [(member op '(div add sub mult))  
                (let-values ([(x-val new-state) (eval (first args) state)]  
                             ...)]  ; Added proper binding for 'op'

_Note: this did not fix the bug_

**Prompt 3 (Further Debugging)**

CatL: I’m getting "op: unbound identifier in: op" in the arithmetic operations section. Here’s my code: [code snippet]

Claude Response: 

1. Replaced match with cond
- This eliminates the pattern matching syntax errors you were encountering
- The cond structure is more straightforward and avoids special pattern matching syntax
2. Used explicit predicates for each case

For each expression type, I check:
- That it's a list
- That it has the expected length
- That the first element is the expected operator/keyword
3. Separated pattern for arithmetic operations
- Checks if the first element is a member of the allowed operations
- Processes arguments and performs the appropriate arithmetic

            #lang racket

            ; Define our success/failure constructors and accessors
            (define (success x) (list 'success x))
            (define (failure msg) (list 'failure msg))
            (define (success? x) (equal? (first x) 'success))
            (define (failure? x) (equal? (first x) 'failure))
            (define (from-success default x)
              (if (success? x) (second x) default))
            (define (from-failure default x)
              (if (failure? x) (second x) default))
            
            (define (safe-div x y)
              (if (= y 0)
                  (failure "Division by zero")
                  (success (/ x y))))
            
            (define in-list?
              (λ (x lst)
                (not (false? (member x lst)))))
            
            ; State management functions
            (define (get-var state name)
              (let ([result (assoc name state)])
                (if result
                    (success (cdr result))
                    (failure (format "Undefined variable: ~a" name)))))
            
            (define (add-var state name value)
              (if (assoc name state)
                  ;; Allow redefinition: update instead
                  (update-var state name value)
                  (values #t (cons (cons name value) state))))
            
            (define (update-var state name value)
              (if (assoc name state)
                  (values #t (map (λ (pair)
                                   (if (equal? (car pair) name)
                                       (cons name value)
                                       pair))
                                 state))
                  (values #f state)))
            
            (define (remove-var state name)
              (filter (λ (pair) (not (equal? (car pair) name))) state))
            
            ; Evaluator
            (define (eval expr state)
              (cond
                ;; Number literal
                [(and (list? expr) (= (length expr) 2) (equal? (first expr) 'num))
                 (values (success (second expr)) state)]
                
                ;; Variable lookup
                [(and (list? expr) (= (length expr) 2) (equal? (first expr) 'id))
                 (get-var state (second expr))]
            
                ;; Define without value (undefined)
                [(and (list? expr) (= (length expr) 2) (equal? (first expr) 'define))
                 (let-values ([(success? new-state) (add-var state (second expr) 'undefined)])
                   (values (success 'undefined) new-state))]
            
                ;; Define with value
                [(and (list? expr) (= (length expr) 3) (equal? (first expr) 'define))
                 (let-values ([(val new-state1) (eval (third expr) state)])
                   (if (failure? val)
                       (values val state)
                       (let ([value (from-success #f val)])
                         (let-values ([(success? new-state2) (add-var new-state1 (second expr) value)])
                           (values (success value) new-state2)))))]
            
                ;; Assignment
                [(and (list? expr) (= (length expr) 3) (equal? (first expr) 'assign))
                 (let-values ([(val new-state1) (eval (third expr) state)])
                   (if (failure? val)
                       (values val state)
                       (let ([value (from-success #f val)])
                         (let-values ([(success? new-state2) (update-var new-state1 (second expr) value)])
                           (if success?
                               (values (success value) new-state2)
                               (values (failure (format "Variable not defined: ~a" (second expr))) state))))))]
            
                ;; Remove
                [(and (list? expr) (= (length expr) 2) (equal? (first expr) 'remove))
                 (if (assoc (second expr) state)
                     (values (success (second expr)) (remove-var state (second expr)))
                     (begin
                       (displayln (format "Error: remove ~a: variable not defined, ignoring" (second expr)))
                       (values (success (second expr)) state)))]
            
                ;; Arithmetic operations
                [(and (list? expr) (not (empty? expr)) (member (first expr) '(div add sub mult / + - *)))
                 (let ([operator (first expr)]
                       [args (rest expr)])
                   (if (not (= (length args) 2))
                       (values (failure "Arithmetic operations require exactly 2 arguments") state)
                       (let-values ([(x-val new-state1) (eval (first args) state)]
                                    [(y-val new-state2) (eval (second args) new-state1)])
                         (if (or (failure? x-val) (failure? y-val))
                             (values (failure (if (failure? x-val)
                                                  (second x-val)
                                                  (second y-val)))
                                     state)
                             (let ([x (from-success #f x-val)]
                                   [y (from-success #f y-val)])
                               (cond
                                 [(or (equal? operator 'div) (equal? operator '/))
                                  (values (safe-div x y) new-state2)]
                                 [(or (equal? operator 'add) (equal? operator '+))
                                  (values (success (+ x y)) new-state2)]
                                 [(or (equal? operator 'sub) (equal? operator '-))
                                  (values (success (- x y)) new-state2)]
                                 [else ; mult or *
                                  (values (success (* x y)) new-state2)]))))))]
            
                ;; Unknown operation
                [(and (list? expr) (not (empty? expr)))
                 (values (failure "Unknown operation") state)]
                
                ;; Invalid expression (not a list or empty list)
                [else 
                 (values (failure "Invalid expression") state)]))
