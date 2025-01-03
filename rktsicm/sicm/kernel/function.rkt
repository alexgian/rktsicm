#lang racket/base

(provide (except-out (all-defined-out) assign-operation))

(require (only-in "../rkt/glue.rkt" if default-object default-object? cons*)
         (only-in racket/syntax format-id)
         "generic.rkt"
         "types.rkt"
         "utils.rkt"
         "cstm/make-plain-procedure.rkt"
         )
(define-values (assign-operation function:assign-operations)
  (make-assign-operations 'function))

(define (p-rename op fct)
  (define a (regexp-replace #px"#<procedure:(.*)>" (format "~a" op) "\\1"))
  (define b (regexp-replace #px"^g:" a ""))
  (define c (regexp-replace #px"^_(.*)_$" b "\\1"))
  (procedure-rename fct (string->symbol (format "f:~a" c))))


;;bdk;; start original file

;;;;            Functions


(define (f:type f) function-type-tag)
(define (f:type-predicate f) function-quantity?)

;;; Arity manipulation procedures are in UTILS.SCM

(define ((f:unary operator) f)
  (p-rename operator (compose-bin operator f)))

(define (f:binary operator)
  (λ (f1 f2)
    (cond
      [(function? f1)
       (cond
         [(function? f2)
          (define arity (joint-arity (g:arity f1) (g:arity f2)))
          (make-plain-procedure-slct 'f:binary-ff
                                     arity
                                     (λ (xs) #`(operator (f1 #,@xs) (f2 #,@xs)))
                                     (λ (xs rst) #`(operator (apply f1 #,@xs #,rst) (apply f2 #,@xs #,rst)))
                                     (λ (xs) #`(#,operator (#,f1 #,@xs) (#,f2 #,@xs)))
                                     (λ (xs rst) #`(#,operator (apply #,f1 #,@xs #,rst) (apply #,f2 #,@xs #,rst))))]
         [(numerical-quantity? f2)
          (define arity (g:arity f1))
          (make-plain-procedure-slct 'f:binary-fn
                                     arity
                                     (λ (xs) #`(operator (f1 #,@xs) f2))
                                     (λ (xs rst) #`(operator (apply f1 #,@xs #,rst) f2))
                                     (λ (xs) #`(#,operator (#,f1 #,@xs) #,f2))
                                     (λ (xs rst) #`(#,operator (apply #,f1 #,@xs #,rst) #,f2)))]
         [else
          (define arity (g:arity f1))
          (make-plain-procedure-slct 'f:binary-fS
                                     arity
                                     (λ (xs) #`(operator (f1 #,@xs) (g:apply f2 (list #,@xs))))
                                     (λ (xs rst) #`(operator (apply f1 #,@xs #,rst) (g:apply f2 (cons* #,@xs #,rst))))
                                     (λ (xs) #`(#,operator (#,f1 #,@xs) (g:apply #,f2 (list #,@xs))))
                                     (λ (xs rst) #`(#,operator (apply #,f1 #,@xs #,rst) (g:apply #,f2 (cons* #,@xs #,rst)))))])]
      [(numerical-quantity? f1)
       (cond
         [(function? f2)
          (define arity (g:arity f2))
          (make-plain-procedure-slct 'f:binary-nf
                                     arity
                                     (λ (xs) #`(operator f1 (f2 #,@xs)))
                                     (λ (xs rst) #`(operator f1 (apply f2 #,@xs #,rst)))
                                     (λ (xs) #`(#,operator #,f1 (#,f2 #,@xs)))
                                     (λ (xs rst) #`(#,operator #,f1 (apply #,f2 #,@xs #,rst))))]
         [(numerical-quantity? f2)
          (error 'f:binary-nn "not possible?")]
         [else
          (error 'f:binary-nS "not possible?")])]
      [else
       (cond
         [(function? f2)
          (define arity (g:arity f2))
          (make-plain-procedure-slct 'f:binary-Sf
                                     arity
                                     (λ (xs) #`(operator (g:apply f1 (list #,@xs)) (f2 #,@xs)))
                                     (λ (xs rst) #`(operator (g:apply f1 (cons* #,@xs #,rst)) (apply f2 #,@xs #,rst)))
                                     (λ (xs) #`(#,operator (g:apply #,f1 (list #,@xs)) (#,f2 #,@xs)))
                                     (λ (xs rst) #`(#,operator (g:apply #,f1 (cons* #,@xs #,rst)) (apply #,f2 #,@xs #,rst))))]
         [(numerical-quantity? f2)
          (error 'f:binary-Sn "not possible?")]
         [else
          (error 'f:binary-SS "not possible?")])])))
#; ;original, doesn't keep arity for a > 3
(define ((f:binary operator) f1 f2)
  (let ((f1 (if (function? f1) f1 (coerce-to-function f1)))
        (f2 (if (function? f2) f2 (coerce-to-function f2))))	
    (let ((a (joint-arity (g:arity f1) (g:arity f2))))
      (if (not a)
          (error "Functions have different arities" f1 f2))
      (cond ((pair:eq? a *at-least-zero*)
             (lambda x
               (operator (apply f1 x) (apply f2 x))))
            ((pair:eq? a *exactly-zero*)
             (lambda ()
               (operator (f1) (f2))))
            ((pair:eq? a *at-least-one*)
             (lambda (x . y)
               (operator (apply f1 x y) (apply f2 x y))))
            ((pair:eq? a *exactly-one*)
             (lambda (x)
               (operator (f1 x) (f2 x))))
            ((pair:eq? a *at-least-two*)
             (lambda (x y . z)
               (operator (apply f1 x y z) (apply f2 x y z))))
            ((pair:eq? a *exactly-two*)
             (lambda (x y)
               (operator (f1 x y) (f2 x y))))
            ((pair:eq? a *at-least-three*)
             (lambda (u x y . z)
               (operator (apply f1 u x y z) (apply f2 u x y z))))
            ((pair:eq? a *exactly-three*)
             (lambda (x y z)
               (operator (f1 x y z) (f2 x y z))))
            ((pair:eq? a *one-or-two*)
             (lambda (x [y default-object])
               (if (default-object? y)
                   (operator (f1 x) (f2 x))
                   (operator (f1 x y) (f2 x y)))))
            (else
             (lambda x
               (operator (apply f1 x) (apply f2 x))))))))

(define (coerce-to-function g)
  ;;bdk;; keep same function if possible (for arity, name, etc)
  (cond ((procedure? g) g)
        ((numerical-quantity? g) (lambda x g))
		(else (lambda x (g:apply g x)))))

(define (f:arity f) (procedure-arity f))

(define (f:zero-like f)			;want (zero-like range-element)
  (lambda any (g:zero-like (apply f any))))

(define (f:one-like f)			;want (one-like range-element)
  (lambda any (g:one-like (apply f any))))

(define (f:identity-like f) g:identity)

(assign-operation 'type            f:type            function?)
(assign-operation 'type-predicate  f:type-predicate  function?)
(assign-operation 'arity           f:arity           function?)

(assign-operation 'inexact?        (f:unary g:inexact?)       function?)

(assign-operation 'zero-like       f:zero-like                function?)
(assign-operation 'one-like        f:one-like                 function?)
(assign-operation 'identity-like   f:identity-like            function?)

;;; The following tests conflict with the conservative theory of
;;; generic predicates in that they return a new procedure with a
;;; deferred test rather than #f, because they cannot know the
;;; result.  Indeed, a user may write (compose zero? f) if necessary.

;;;(assign-operation 'zero?           (f:unary g:zero?)          function?)
;;;(assign-operation 'one?            (f:unary g:one?)           function?)
;;;(assign-operation 'identity?       (f:unary g:identity?)      function?)

(assign-operation 'negate          (f:unary g:negate)         function?)
(assign-operation 'invert          (f:unary g:invert)         function?)

(assign-operation 'sqrt            (f:unary g:sqrt)           function?)
(assign-operation 'square          (f:unary g:square)         function?)

(assign-operation 'exp             (f:unary g:exp)            function?)
(assign-operation 'log             (f:unary g:log)            function?)

(assign-operation 'sin             (f:unary g:sin)            function?)
(assign-operation 'cos             (f:unary g:cos)            function?)

(assign-operation 'asin            (f:unary g:asin)           function?)
(assign-operation 'acos            (f:unary g:acos)           function?)

(assign-operation 'sinh            (f:unary g:sinh)           function?)
(assign-operation 'cosh            (f:unary g:cosh)           function?)

(assign-operation 'abs             (f:unary g:abs)            function?)

(assign-operation 'determinant     (f:unary g:determinant)    function?)
(assign-operation 'trace           (f:unary g:trace)          function?)

;;; Binary operations on functions are a bit weird.  A special predicate
;;; are needed to make the correct coercions possible:

;;; Tests must be conservative.
;;;(assign-operation '=               (f:binary g:=)             function? function?)

(assign-operation '+                  (f:binary g:+)             function? cofunction?)
(assign-operation '+                  (f:binary g:+)             cofunction? function?)
(assign-operation '-                  (f:binary g:-)             function? cofunction?)
(assign-operation '-                  (f:binary g:-)             cofunction? function?)
(assign-operation '*                  (f:binary g:*)             function? cofunction?)
(assign-operation '*                  (f:binary g:*)             cofunction? function?)
(assign-operation '/                  (f:binary g:/)             function? cofunction?)
(assign-operation '/                  (f:binary g:/)             cofunction? function?)

(assign-operation 'dot-product        (f:binary g:dot-product)   function? cofunction?)
(assign-operation 'dot-product        (f:binary g:dot-product)   cofunction? function?)

(assign-operation 'cross-product      (f:binary g:cross-product)   function? cofunction?)
(assign-operation 'cross-product      (f:binary g:cross-product)   cofunction? function?)

(assign-operation 'expt               (f:binary g:expt)          function? cofunction?)
(assign-operation 'expt               (f:binary g:expt)          cofunction? function?)

(assign-operation 'gcd                (f:binary g:gcd)           function? cofunction?)
(assign-operation 'gcd                (f:binary g:gcd)           cofunction? function?)

(assign-operation 'make-rectangular   (f:binary g:make-rectangular)
	                                                        function? cofunction?)
(assign-operation 'make-rectangular   (f:binary g:make-rectangular)
	                                                        cofunction? function?)

(assign-operation 'make-polar         (f:binary g:make-polar)    function? cofunction?)
(assign-operation 'make-polar         (f:binary g:make-polar)    cofunction? function?)

(assign-operation 'real-part          (f:unary g:real-part)      function?)
(assign-operation 'imag-part          (f:unary g:imag-part)      function?)
(assign-operation 'magnitude          (f:unary g:magnitude)      function?)
(assign-operation 'angle              (f:unary g:angle)          function?)

;(assign-operation 'conjugate         (f:unary g:conjugate)      function?)

(assign-operation 'atan1              (f:unary g:atan)           function?)
(assign-operation 'atan2              (f:binary g:atan)          function? cofunction?)
(assign-operation 'atan2              (f:binary g:atan)          cofunction? function?)

(assign-operation 'solve-linear-right      (f:binary g:solve-linear-right)  function? cofunction?)
(assign-operation 'solve-linear-right      (f:binary g:solve-linear-right)  cofunction? function?)

(assign-operation 'solve-linear-left      (f:binary g:solve-linear-left)  cofunction? function?)
(assign-operation 'solve-linear-left      (f:binary g:solve-linear-left)  function? cofunction?)

(assign-operation 'solve-linear      (f:binary g:solve-linear)  cofunction? function?)
(assign-operation 'solve-linear      (f:binary g:solve-linear)  function? cofunction?)

;;; This only makes sense for linear functions...
(define (((f:transpose f) g) a)
  (g (f a)))

(assign-operation 'transpose          f:transpose                function?)

#|
;;; 

(define (transpose-defining-relation T g a)
  ;; T is a linear transformation T:V -> W
  ;; the transpose of T, T^t:W* -> V* 
  ;; Forall a in V, g in W*,  g:W -> R
  ;; (T^t(g))(a) = g(T(a)).
  (- (((f:transpose T) g) a) (g (T a))))

(let ((DTf
	(let ((T (literal-function 'T (-> (UP Real Real) (UP Real Real Real)))))
	  (let ((DT (D T)))
	    (lambda (s)
	      (lambda (x)
		(* (DT s) x))))))

      (a (up 'a^0 'a^1))
      (g (lambda (w) (* (down 'g_0 'g_1 'g_2) w)))

      (s (up 'x 'y)))
  (pec (transpose-defining-relation (DTf s) g a))
  (((f:transpose (DTf s)) g) a))

#| Result: 0 |#
#|
(+ (* a^0 g_0 (((partial 0) T^0) (up x y)))
   (* a^0 g_1 (((partial 0) T^1) (up x y)))
   (* a^0 g_2 (((partial 0) T^2) (up x y)))
   (* a^1 g_0 (((partial 1) T^0) (up x y)))
   (* a^1 g_1 (((partial 1) T^1) (up x y)))
   (* a^1 g_2 (((partial 1) T^2) (up x y))))
|#

|#
