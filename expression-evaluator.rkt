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
        (values (success (cdr result)) state)
        (values (failure (format "Undefined variable: ~a" name)) state))))

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
     (let*-values ([(val state1) (eval (third expr) state)])
       (if (failure? val)
           (values val state)
           (let ([value (from-success #f val)])
             (let-values ([(success? state2) (add-var state1 (second expr) value)])
               (values (success value) state2)))))]

    ;; Assignment
    [(and (list? expr) (= (length expr) 3) (equal? (first expr) 'assign))
     (let*-values ([(val state1) (eval (third expr) state)])
       (if (failure? val)
           (values val state)
           (let ([value (from-success #f val)])
             (let-values ([(success? state2) (update-var state1 (second expr) value)])
               (if success?
                   (values (success value) state2)
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
           (let*-values ([(x-val state1) (eval (first args) state)]
                        [(y-val state2) (eval (second args) state1)])
             (if (or (failure? x-val) (failure? y-val))
                 (values (failure (if (failure? x-val)
                                      (second x-val)
                                      (second y-val)))
                         state)
                 (let ([x (from-success #f x-val)]
                       [y (from-success #f y-val)])
                   (cond
                     [(or (equal? operator 'div) (equal? operator '/))
                      (values (safe-div x y) state2)]
                     [(or (equal? operator 'add) (equal? operator '+))
                      (values (success (+ x y)) state2)]
                     [(or (equal? operator 'sub) (equal? operator '-))
                      (values (success (- x y)) state2)]
                     [else ; mult or *
                      (values (success (* x y)) state2)]))))))]

    ;; Unknown operation
    [(and (list? expr) (not (empty? expr)))
     (values (failure "Unknown operation") state)]
    
    ;; Invalid expression (not a list or empty list)
    [else 
     (values (failure "Invalid expression") state)]))

(define (repl [state '()])
  (display "> ")
  (let ([input (read)])
    (unless (equal? input 'quit)
      (let-values ([(result new-state) (eval input state)])
        (displayln (format "Result: ~a" result))
        (displayln (format "State: ~a" new-state))
        (repl new-state)))))

; Start the REPL
(displayln "Welcome to the Simple Interpreter")
(displayln "Enter expressions or 'quit' to exit")
(repl)