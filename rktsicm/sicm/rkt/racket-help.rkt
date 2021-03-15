#lang racket/base

(require (for-syntax racket/base)
         racket/list
         racket/math
         racket/stream)

(provide (all-defined-out)
         append-map make-list)

(define ignored-error (gensym 'ignored-error))
(define (ignored-error? x) (eq? ignored-error x))

(define (warn . rst)
  (cond
    [(null? rst) (println "warning")]
    [else
     (print (car rst))
     (for ([p (in-list (cdr rst))]) (printf " ~a" p))
     (newline)]))


(define (for-all? lst pred) (andmap pred lst))
(define (delv a lst) (remv* (list a) lst))
(define (symbol . rst) (string->symbol (apply string-append (map (λ (x) (format "~a" x)) rst))))
(define-syntax-rule (ignore-errors rst ...) (with-handlers ([exn:fail? void]) rst ...))
(define (there-exists? lst pred) (for/or ([i (in-list lst)]) (pred i)))
