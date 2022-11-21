#lang racket/base

(require rackunit
         "../../main.rkt"
         "../helper.rkt"
         )

(void (clear-arguments)
      (suppress-arguments (list '(up x0 y0 z0))))
(define the-tests
  (test-suite
   "calculus/hodge-star"
   (test-case
    "c1"
    (define-coordinates (up x y) R2-rect)
    (define (E2-metric v1 v2)
      (+ (* (dx v1) (dx v2))
         (* (dy v1) (dy v2))))
    (define omega (wedge dx dy))
    (define E2-star
      (Hodge-star E2-metric
                  (coordinate-system->basis R2-rect)))
    (check-simplified? ((E2-star omega)
                        ((point R2-rect) (up 'x 'y)))
                       1)
    ;;; What is a rank 0 form?
    (check-simplified? (((E2-star dx)
                         (literal-vector-field 'V R2-rect))
                        ((point R2-rect) (up 'x 'y)))
                       '(V^1 (up x y)))
    (check-simplified? (((E2-star dy)
                         (literal-vector-field 'V R2-rect))
                        ((point R2-rect) (up 'x 'y)))
                       '(* -1 (V^0 (up x y))))
    (check-simplified? (((E2-star (lambda (pt) 1))
                         (literal-vector-field 'V R2-rect)
                         (literal-vector-field 'W R2-rect))
                        ((point R2-rect) (up 'x 'y)))
                       '(+ (* (V^0 (up x y)) (W^1 (up x y)))
                           (* -1 (V^1 (up x y)) (W^0 (up x y))))))
   (test-case
    "some simple tests on 3-dimensional Euclidean space"
    (define-coordinates (up x y z) R3-rect)
    (define R3-point ((R3-rect '->point) (up 'x0 'y0 'z0)))
    (define R3-basis (coordinate-system->basis R3-rect))
    (define (E3-metric v1 v2)
      (+ (* (dx v1) (dx v2))
         (* (dy v1) (dy v2))
         (* (dz v1) (dz v2))))
    (define E3-star (Hodge-star E3-metric R3-rect))
    (check-simplified? (((- (E3-star (lambda (pt) 1))
                            (wedge dx dy dz))
                         (literal-vector-field 'u R3-rect)
                         (literal-vector-field 'v R3-rect)
                         (literal-vector-field 'w R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((- (E3-star dx)
                            (wedge dy dz))
                         (literal-vector-field 'u R3-rect)
                         (literal-vector-field 'v R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((+ (E3-star (wedge dx dz)) dy)
                         (literal-vector-field 'u R3-rect))
                        R3-point)
                       0)
    (check-simplified? ((- (E3-star (wedge dx dy dz)) 1)
                        R3-point)
                       0)
    (check-simplified? (((E3-star (literal-scalar-field 'f R3-rect))
                         (literal-vector-field 'u R3-rect)
                         (literal-vector-field 'v R3-rect)
                         (literal-vector-field 'w R3-rect))
                        R3-point)
                       '(+ (* w^2 u^0 f v^1)
                           (* -1 w^2 u^1 v^0 f)
                           (* -1 u^0 v^2 w^1 f)
                           (* v^2 u^1 w^0 f)
                           (* u^2 w^1 v^0 f)
                           (* -1 u^2 w^0 f v^1)))
    (check-simplified? (((E3-star (literal-1form-field 'omega R3-rect))
                         (literal-vector-field 'u R3-rect)
                         (literal-vector-field 'v R3-rect))
                        R3-point)
                       '(+ (* v^1 u^0 omega_2)
                           (* -1 v^1 u^2 omega_0)
                           (* -1 v^2 u^0 omega_1)
                           (* v^2 u^1 omega_0)
                           (* u^2 v^0 omega_1)
                           (* -1 u^1 v^0 omega_2)))
    (check-simplified? (((E3-star
                          (+ (* (literal-scalar-field 'alpha R3-rect) (wedge dx dy))
                             (* (literal-scalar-field 'beta R3-rect) (wedge dy dz))
                             (* (literal-scalar-field 'gamma R3-rect) (wedge dz dx))))
                         (literal-vector-field 'u R3-rect))
                        R3-point)
                       '(+ (* u^0 beta) (* u^2 alpha) (* u^1 gamma)))
    (check-simplified? ((E3-star
                         (* (literal-scalar-field 'alpha R3-rect) (wedge dx dy dz)))
                        R3-point)
                       'alpha)
    ;;; omega = alpha*dx + beta*dy + gamma*dz
    (define omega
      (+ (* (literal-scalar-field 'alpha R3-rect)  dx)
         (* (literal-scalar-field 'beta R3-rect)   dy)
         (* (literal-scalar-field 'gamma R3-rect)  dz)))
    (check-simplified? (((E3-star omega)
                         (literal-vector-field 'u R3-rect)
                         (literal-vector-field 'v R3-rect))
                        R3-point)
                       '(+ (* v^1 u^0 gamma)
                           (* -1 v^1 u^2 alpha)
                           (* -1 v^2 u^0 beta)
                           (* v^2 u^1 alpha)
                           (* u^2 v^0 beta)
                           (* -1 u^1 v^0 gamma)))
    ;;; *omega = alpha*dy^dz - beta*dx^dz + gamma*dx^dy
    (check-simplified? (((E3-star (d omega))
                         (literal-vector-field 'u R3-rect))
                        R3-point)
                       '(+ (* u^0 ((partial 1) gamma))
                           (* -1 u^0 ((partial 2) beta))
                           (* u^2 ((partial 0) beta))
                           (* -1 u^2 ((partial 1) alpha))
                           (* -1 u^1 ((partial 0) gamma))
                           (* u^1 ((partial 2) alpha))))
    ;;; Indeed, *d is the curl operator.
    (check-simplified? (((d (E3-star omega))
                         (literal-vector-field 'u R3-rect)
                         (literal-vector-field 'v R3-rect)
                         (literal-vector-field 'w R3-rect))
                        R3-point)
                       '(+ (* w^2 v^1 u^0 ((partial 0) alpha))
                           (* w^2 v^1 u^0 ((partial 1) beta))
                           (* w^2 v^1 u^0 ((partial 2) gamma))
                           (* -1 w^2 u^1 v^0 ((partial 0) alpha))
                           (* -1 w^2 u^1 v^0 ((partial 1) beta))
                           (* -1 w^2 u^1 v^0 ((partial 2) gamma))
                           (* -1 v^1 w^0 u^2 ((partial 0) alpha))
                           (* -1 v^1 w^0 u^2 ((partial 1) beta))
                           (* -1 v^1 w^0 u^2 ((partial 2) gamma))
                           (* -1 v^2 w^1 u^0 ((partial 0) alpha))
                           (* -1 v^2 w^1 u^0 ((partial 1) beta))
                           (* -1 v^2 w^1 u^0 ((partial 2) gamma))
                           (* v^2 w^0 u^1 ((partial 0) alpha))
                           (* v^2 w^0 u^1 ((partial 1) beta))
                           (* v^2 w^0 u^1 ((partial 2) gamma))
                           (* w^1 u^2 v^0 ((partial 0) alpha))
                           (* w^1 u^2 v^0 ((partial 1) beta))
                           (* w^1 u^2 v^0 ((partial 2) gamma))))
    (check-simplified? ((E3-star (d (E3-star omega)))
                        R3-point)
                       '(+ ((partial 0) alpha) ((partial 1) beta) ((partial 2) gamma)))
    ;;; Indeed, *d* is the divergence operator...
    )
   (test-case
    "a 2+1 Minkowski space with c=1"
    (define-coordinates (up t x y) R3-rect)
    (define R3-point ((R3-rect '->point) (up 't0 'x0 'y0)))
    (define R3-basis (coordinate-system->basis R3-rect))
    (define (L3-metric u v)
      (+ (* -1 (dt u) (dt v))
         (* (dx u) (dx v))
         (* (dy u) (dy v))))
    (define L3-star (Hodge-star L3-metric R3-rect))
    (check-simplified? ((L3-metric d/dt d/dt) R3-point) -1)
    (check-simplified? (((- (L3-star (lambda (m) 1))
                            (wedge dx dy dt))
                         (literal-vector-field 'U R3-rect)
                         (literal-vector-field 'V R3-rect)
                         (literal-vector-field 'W R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((- (L3-star dx)
                            (wedge dy dt))
                         (literal-vector-field 'U R3-rect)
                         (literal-vector-field 'V R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((- (L3-star dy)
                            (wedge dt dx))
                         (literal-vector-field 'U R3-rect)
                         (literal-vector-field 'V R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((- (L3-star dt)
                            (wedge dy dx))
                         (literal-vector-field 'U R3-rect)
                         (literal-vector-field 'V R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((- (L3-star (wedge dx dy)) dt)
                         (literal-vector-field 'U R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((+ (L3-star (wedge dy dt)) dx)
                         (literal-vector-field 'U R3-rect))
                        R3-point)
                       0)
    (check-simplified? (((+ (L3-star (wedge dt dx)) dy)
                         (literal-vector-field 'U R3-rect))
                        R3-point)
                       0)
    (check-simplified? ((+ (L3-star (wedge dx dy dt)) 1)
                        R3-point)
                       0))
   (test-case
    "a 1-1 Minkowski space with c"
    (define-coordinates (up t x) R2-rect)
    (define R2-point ((R2-rect '->point) (up 't0 'x0)))
    (define R2-basis (coordinate-system->basis R2-rect))
    (define c 'c)
    (define (L2-metric u v)
      (+ (* -1 c c (dt u) (dt v))
         (* 1 (dx u) (dx v))))
    (define L2-Hodge-star* (Hodge-star L2-metric R2-rect))
    (check-simplified? (((L2-Hodge-star* (lambda (x) 1))
                         (literal-vector-field 'u R2-rect)
                         (literal-vector-field 'v R2-rect))
                        R2-point)
                       '(+ (* (u^0 (up t0 x0)) (v^1 (up t0 x0)))
                           (* -1 (u^1 (up t0 x0)) (v^0 (up t0 x0)))))
    ;;; Wrong.  Must generally orthonormalize.
    (define L2-Hodge-star (Hodge-star L2-metric R2-rect #t))
    (check-simplified? (((L2-Hodge-star (lambda (x) 1))
                         (literal-vector-field 'u R2-rect)
                         (literal-vector-field 'v R2-rect))
                        R2-point)
                       '(+ (* c (u^0 (up t0 x0)) (v^1 (up t0 x0)))
                           (* -1 c (v^0 (up t0 x0)) (u^1 (up t0 x0)))) ; = cdt^dx(u v)
                       )
    ;;; Can accelerate by explicitly passing in an explicitly constructed
    ;;; orthonormal constant basis.
    (let ()
      (define L2-basis (orthonormalize R2-basis L2-metric R2-rect))
      (define L2-vector-basis (basis->vector-basis L2-basis))
      (check-simplified? (accumulate pe (s:foreach (lambda (v)
                                                     (pe ((v (literal-manifold-function 'f R2-rect))
                                                          R2-point)))
                                                   L2-vector-basis))
                         '((/ (((partial 0) f) (up t0 x0)) c)
                           (((partial 1) f) (up t0 x0))))
      (define L2-1form-basis (vector-basis->dual L2-vector-basis R2-rect))
      (check-simplified? (accumulate pe (s:foreach (lambda (omega)
                                                     (pe ((omega (literal-vector-field 'v R2-rect))
                                                          R2-point)))
                                                   L2-1form-basis))
                         '((* c (v^0 (up t0 x0)))
                           (v^1 (up t0 x0))))
      (check-simplified? ((L2-1form-basis L2-vector-basis) R2-point)
                         '(up (down 1 0) (down 0 1))))
    (let ()
      ;;; Now make constant basis...
      (define L2-constant-vector-basis (down (* (/ 1 c) d/dt) d/dx))
      (define L2-constant-1form-basis (up (* c dt) dx))
      (define L2-constant-basis (make-basis L2-constant-vector-basis
                                            L2-constant-1form-basis))
      (define L2-Hodge-star(Hodge-star L2-metric L2-constant-basis))
      (check-simplified? (((L2-Hodge-star (lambda (x) 1))
                           (literal-vector-field 'u R2-rect)
                           (literal-vector-field 'v R2-rect))
                          R2-point)
                         '(+ (* -1 c (v^0 (up t0 x0)) (u^1 (up t0 x0)))
                             (* c (v^1 (up t0 x0)) (u^0 (up t0 x0)))))
      ;;; As desired.
      (check-simplified? (((L2-Hodge-star
                            (* (literal-manifold-function 'alpha R2-rect)
                               (* c dt)))
                           (literal-vector-field 'u R2-rect))
                          R2-point)
                         '(* -1 (alpha (up t0 x0)) (u^1 (up t0 x0))) ; = -alpha dx(u)
                         )
      (check-simplified? (((L2-Hodge-star
                            (* (literal-manifold-function 'alpha R2-rect)
                               dx))
                           (literal-vector-field 'u R2-rect))
                          R2-point)
                         '(* -1 c (alpha (up t0 x0)) (u^0 (up t0 x0))) ; = -alpha c dt(u)
                         )
      (check-simplified? ((L2-Hodge-star
                           (* (literal-manifold-function 'alpha R2-rect)
                              (wedge (* c dt) dx)))
                          R2-point)
                         '(* -1 (alpha (up t0 x0))))))
   (test-case
    "c5"
    (define-coordinates (up x y) R2-rect)
    (define R2-point ((R2-rect '->point) (up 'x0 'y0)))
    (define R2-basis (coordinate-system->basis R2-rect))
    (define ((g-R2 g_00 g_01 g_11) u v)
      (+ (* g_00 (dx u) (dx v))
         (* g_01 (+ (* (dx u) (dy v)) (* (dy u) (dx v))))
         (* g_11 (dy u) (dy v))))
    (define R2-metric (g-R2 'a 'b 'c))
    ;;; Hodge-star must Orthonormalize here
    (define R2-star (Hodge-star R2-metric R2-rect #t))
    (check-simplified? (((R2-star (lambda (x) 1)) d/dx d/dy) R2-point)
                       '(sqrt (+ (* a c) (* -1 (expt b 2)))))
    (check-simplified? (((R2-star dx) d/dx) R2-point)
                       '(/ (* b (sqrt a)) (sqrt (+ (* (expt a 2) c) (* -1 a (expt b 2)))))
                       ;;same but simplifier can't 
                       #;'(/ b (sqrt (+ (* a c) (* -1 (expt b 2))))))
    (check-simplified? (((R2-star dx) d/dy) R2-point)
                       '(/ (* c (sqrt a)) (sqrt (+ (* (expt a 2) c) (* -1 a (expt b 2)))))
                       ;;same but simplifier can't 
                       #;'(/ c (sqrt (+ (* a c) (* -1 (expt b 2))))))
    (check-simplified? (((R2-star dy) d/dx) R2-point)
                       '(/ (* -1 (expt a 2)) (* (sqrt a) (sqrt (+ (* (expt a 2) c) (* -1 a (expt b 2))))))
                       ;;same but simplifier can't 
                       #;'(/ (* -1 a) (sqrt (+ (* a c) (* -1 (expt b 2))))))
    (check-simplified? (((R2-star dy) d/dy) R2-point)
                       '(/ (* -1 b (sqrt a)) (sqrt (+ (* (expt a 2) c) (* -1 a (expt b 2)))))
                       ;;same but simplifier can't 
                       #;'(/ (* -1 b) (sqrt (+ (* a c) (* -1 (expt b 2))))))
    (check-simplified? ((R2-star (wedge dx dy)) R2-point)
                       '(/ 1 (sqrt (+ (* a c) (* -1 (expt b 2)))))))
   (test-case
    "Example: Lorentz metric on R^4"
    (define SR R4-rect)
    (define-coordinates (up t x y z) SR)
    (define SR-point ((SR '->point) (up 't0 'x0 'y0 'z0)))
    (define c 'c)
    (define SR-constant-vector-basis (down (* (/ 1 c) d/dt) d/dx d/dy d/dz))
    (define SR-constant-1form-basis (up (* c dt) dx dy dz))
    (define SR-constant-basis
      (make-basis SR-constant-vector-basis
                  SR-constant-1form-basis))
    (define (g-Lorentz u v)
      (+ (* (dx u) (dx v))
         (* (dy u) (dy v))
         (* (dz u) (dz v))
         (* -1 (square c) (dt u) (dt v))))
    (define SR-star (Hodge-star g-Lorentz SR-constant-basis))
    (define u
      (+ (* (literal-manifold-function 'ut SR) (/ 1 c) d/dt)
         (* (literal-manifold-function 'ux SR) d/dx)
         (* (literal-manifold-function 'uy SR) d/dy)
         (* (literal-manifold-function 'uz SR) d/dz)))
    (define v
      (+ (* (literal-manifold-function 'vt SR) (/ 1 c) d/dt)
         (* (literal-manifold-function 'vx SR) d/dx)
         (* (literal-manifold-function 'vy SR) d/dy)
         (* (literal-manifold-function 'vz SR) d/dz)))
    (check-simplified? (((- (SR-star (wedge dy dz)) (wedge (* c dt) dx))
                         u v)
                        SR-point)
                       0)
    (check-simplified? (((- (SR-star (wedge dz dx)) (wedge (* c dt) dy))
                         u v)
                        SR-point)
                       0)
    ;;; Other rotations of variables are all similar
    )
   (test-case
    "Claim: this is the interior product in a metric space"
    (define (((ip metric basis) X) alpha)
      (let ((k (get-rank alpha))
            (n (basis->dimension basis))
            (dual (Hodge-star metric basis)))
        (let ((sign (if (even? (* k (- n k))) +1 -1)))
          (* sign
             (dual (wedge (dual alpha)
                          ((lower metric) X)))))))
    (define-coordinates (up x y z) R3-rect)
    (define R3-basis (coordinate-system->basis R3-rect))
    (define R3-point ((R3-rect '->point) (up 'x0 'y0 'z0)))
    (define u (literal-vector-field 'u R3-rect))
    (define v (literal-vector-field 'v R3-rect))
    (define w (literal-vector-field 'w R3-rect))
    (define (E3-metric v1 v2)
      (+ (* (dx v1) (dx v2))
         (* (dy v1) (dy v2))
         (* (dz v1) (dz v2))))
    (define omega
      (+ (* (literal-manifold-function 'alpha R3-rect) (wedge dx dy))
         (* (literal-manifold-function 'beta  R3-rect) (wedge dy dz))
         (* (literal-manifold-function 'gamma R3-rect) (wedge dz dx))))
    (check-simplified? (- (((((ip E3-metric R3-basis) u) omega) v) R3-point)
                          ((((interior-product u) omega) v) R3-point))
                       0)
    (define theta (* (literal-scalar-field 'delta R3-rect) (wedge dx dy dz)))
    (check-simplified? (- (((((ip E3-metric R3-basis) u) theta) v w) R3-point)
                          ((((interior-product u) theta) v w) R3-point))
                       0))
   (test-case
    "Electrodynamics"
    (define SR R4-rect)
    (define-coordinates (up t x y z) SR)
    (define SR-basis (coordinate-system->basis SR))
    (define an-event ((SR '->point) (up 't0 'x0 'y0 'z0)))
    (define c 'c)
    (define (g-Lorentz u v)
      (+ (* (dx u) (dx v))
         (* (dy u) (dy v))
         (* (dz u) (dz v))
         (* -1 (square c) (dt u) (dt v))))
    (define L4-constant-vector-basis (down (* (/ 1 c) d/dt) d/dx d/dy d/dz))
    (define L4-constant-1form-basis (up (* c dt) dx dy dz))
    (define L4-constant-basis
      (make-basis L4-constant-vector-basis
                  L4-constant-1form-basis))
    (define SR-star (Hodge-star g-Lorentz L4-constant-basis))
    (check-simplified? (((SR-star
                          (* (literal-manifold-function 'Bx SR)
                             (wedge dy dz)))
                         (* (/ 1 c) d/dt)
                         d/dx)
                        an-event)
                       '(Bx (up t0 x0 y0 z0)))
    ;;; Fields E, B.  From MTW p.108
    (define (Faraday Ex Ey Ez Bx By Bz)
      (+ (* Ex c (wedge dx dt))
         (* Ey c (wedge dy dt))
         (* Ez c (wedge dz dt))
         (* Bx (wedge dy dz))
         (* By (wedge dz dx))
         (* Bz (wedge dx dy))))
    (define (Maxwell Ex Ey Ez Bx By Bz)
      (+ (* -1 Bx c (wedge dx dt))
         (* -1 By c (wedge dy dt))
         (* -1 Bz c (wedge dz dt))
         (* Ex (wedge dy dz))
         (* Ey (wedge dz dx))
         (* Ez (wedge dx dy))))
    (check-simplified? (((- (SR-star (Faraday 'Ex 'Ey 'Ez 'Bx 'By 'Bz))
                            (Maxwell 'Ex 'Ey 'Ez 'Bx 'By 'Bz))
                         (literal-vector-field 'u SR)
                         (literal-vector-field 'v SR))
                        an-event)
                       0)
    ;;; **F + F = 0
    (check-simplified? (((+ ((compose SR-star SR-star) (Faraday 'Ex 'Ey 'Ez 'Bx 'By 'Bz))
                            (Faraday 'Ex 'Ey 'Ez 'Bx 'By 'Bz))
                         (literal-vector-field 'u SR)
                         (literal-vector-field 'v SR))
                        an-event)
                       0)
    ;;; Defining the 4-current density J.
    ;;; Charge density is a manifold function.  Current density is a
    ;;; vector field having only spatial components.
    (define (J charge-density Jx Jy Jz)
      (- (* (/ 1 c) (+ (* Jx dx) (* Jy dy) (* Jz dz)))
         (* charge-density c dt)))
    (define rho (literal-manifold-function 'rho SR))
    (define 4-current
      (J rho
         (literal-manifold-function 'Ix SR)
         (literal-manifold-function 'Iy SR)
         (literal-manifold-function 'Iz SR)))
    (void (((d (SR-star 4-current))
                         (literal-vector-field 'a SR)
                         (literal-vector-field 'b SR)
                         (literal-vector-field 'c SR)
                         (literal-vector-field 'd SR))
                        an-event)
                       ;;; The charge conservation equations are too ugly to include.
                       )
    (check-simplified? (((SR-star 4-current) d/dx d/dy d/dz) an-event)
                       '(rho (up t0 x0 y0 z0)))
    (check-simplified? (((SR-star 4-current)
                         (* (/ 1 c) d/dt) d/dy d/dz)
                        an-event)
                       '(/ (* -1 (Ix (up t0 x0 y0 z0))) c))
    (check-simplified? (((SR-star 4-current)
                         (* (/ 1 c) d/dt) d/dz d/dx)
                        an-event)
                       '(/ (* -1 (Iy (up t0 x0 y0 z0))) c))
    (check-simplified? (((SR-star 4-current)
                         (* (/ 1 c) d/dt) d/dx d/dy)
                        an-event)
                       '(/ (* -1 (Iz (up t0 x0 y0 z0))) c))
    ;;; Maxwell's equations in the form language are:
    ;;; dF=0, d(*F)=4pi *J
    (define F
      (Faraday (literal-manifold-function 'Ex SR)
               (literal-manifold-function 'Ey SR)
               (literal-manifold-function 'Ez SR)
               (literal-manifold-function 'Bx SR)
               (literal-manifold-function 'By SR)
               (literal-manifold-function 'Bz SR)))
    ;;; div B = 0
    (check-simplified? (((d F) d/dx d/dy d/dz) an-event)
                       '(+ (((partial 1) Bx) (up t0 x0 y0 z0))
                           (((partial 2) By) (up t0 x0 y0 z0))
                           (((partial 3) Bz) (up t0 x0 y0 z0))))
    ;;; curl E = -1/c dB/dt
    (check-simplified? (((d F) (* (/ 1 c) d/dt) d/dy d/dz) an-event)
                       '(+ (((partial 2) Ez) (up t0 x0 y0 z0))
                           (* -1 (((partial 3) Ey) (up t0 x0 y0 z0)))
                           (/ (((partial 0) Bx) (up t0 x0 y0 z0)) c)))
    (check-simplified? (((d F) (* (/ 1 c) d/dt) d/dz d/dx) an-event)
                       '(+ (((partial 3) Ex) (up t0 x0 y0 z0))
                           (* -1 (((partial 1) Ez) (up t0 x0 y0 z0)))
                           (/ (((partial 0) By) (up t0 x0 y0 z0)) c)))
    (check-simplified? (((d F) (* (/ 1 c) d/dt) d/dx d/dy) an-event)
                       '(+ (((partial 1) Ey) (up t0 x0 y0 z0))
                           (* -1 (((partial 2) Ex) (up t0 x0 y0 z0)))
                           (/ (((partial 0) Bz) (up t0 x0 y0 z0)) c)))
    ;;; div E = 4pi rho
    (check-simplified? (((- (d (SR-star F)) (* '4pi (SR-star 4-current)))
                         d/dx d/dy d/dz)
                        an-event)
                       '(+ (* -1 4pi (rho (up t0 x0 y0 z0)))
                           (((partial 1) Ex) (up t0 x0 y0 z0))
                           (((partial 2) Ey) (up t0 x0 y0 z0))
                           (((partial 3) Ez) (up t0 x0 y0 z0))))
    ;;; curl B = 1/c dE/dt + 4pi I
    (check-simplified? (((- (d (SR-star F)) (* '4pi (SR-star 4-current)))
                         (* (/ 1 'c) d/dt) d/dy d/dz)
                        an-event)
                       '(+ (/ (* 4pi (Ix (up t0 x0 y0 z0))) c)
                           (* -1 (((partial 2) Bz) (up t0 x0 y0 z0)))
                           (((partial 3) By) (up t0 x0 y0 z0))
                           (/ (((partial 0) Ex) (up t0 x0 y0 z0)) c)))
    (check-simplified? (((- (d (SR-star F)) (* '4pi (SR-star 4-current)))
                         (* (/ 1 c) d/dt) d/dz d/dx)
                        an-event)
                       '(+ (/ (* 4pi (Iy (up t0 x0 y0 z0))) c)
                           (* -1 (((partial 3) Bx) (up t0 x0 y0 z0)))
                           (((partial 1) Bz) (up t0 x0 y0 z0))
                           (/ (((partial 0) Ey) (up t0 x0 y0 z0)) c)))
    (check-simplified? (((- (d (SR-star F)) (* '4pi (SR-star 4-current)))
                         (* (/ 1 c) d/dt) d/dx d/dy)
                        an-event)
                       '(+ (/ (* 4pi (Iz (up t0 x0 y0 z0))) c)
                           (* -1 (((partial 1) By) (up t0 x0 y0 z0)))
                           (((partial 2) Bx) (up t0 x0 y0 z0))
                           (/ (((partial 0) Ez) (up t0 x0 y0 z0)) c))))
   ))

(module+ test
  (require rackunit/text-ui)
  (run-tests the-tests))