#lang typed/racket

(require "types.rkt"
         "canonicalize.rkt")

(provide write-seat-requirements-log)

;; utility function for printing out seat requirement lists:

;; given two orderings, return a new one that uses the first one,
;; but if two are equal according to the first one, uses the second.
(: combine-ordering-lexicographically (All (T) (-> (-> T T Boolean) (-> T T Boolean) (-> T T Boolean))))
(define (combine-ordering-lexicographically <1 <2)
  (λ ([a : T] [b : T])
    (cond [(<1 a b) #t]
          [(<1 b a) #f]
          [else (<2 a b)])))

;; given a projection and a comparison, return a comparison that
;; does the projection then the comparison
(: lift-< (All (T U) (-> (-> T U) (-> U U Boolean) (-> T T Boolean))))
(define (lift-< projector <1)
  (λ (a b) (<1 (projector a) (projector b))))

(: </f (-> (U Real False) (U Real False) Boolean))
(define (</f a b)
  (cond [(and (not a) b) #t]
        [(and a (not b)) #f]
        [(and (not a) (not b)) #f]
        [else (< a b)]))

;; a sort key for a ReqName (put groups before courses):
(define (course-or-group-key [a : ReqName]) : String
  (cond [(string? a) (string-append "C" a)]
        [else (string-append "G" (symbol->string (first a)))]))

(define seat-requirement-<
  (combine-ordering-lexicographically
   (lift-< (compose course-or-group-key Seat-Requirement-course) string<?)
   (lift-< Seat-Requirement-qtr-req </f)))

;; fractional representation makes comparison almost impossible...
  (define (round-requirement [req : Seat-Requirement])
    (Seat-Requirement (Seat-Requirement-label req)
                      (Seat-Requirement-course req)
                      (Seat-Requirement-qtr-req req)
                      (ceiling (Seat-Requirement-seats req))))

;; given a list of seat requirements and a path, write the seat requirements
;; to the file, ordered by course then qtr and ceilinged to the nearest student
(define (write-seat-requirements-log
         [seat-requirements : (Listof Seat-Requirement)]
         [outfile : Path-String])
  (call-with-output-file outfile
    #:exists 'truncate
    (λ ([port : Output-Port])
      (pretty-display
       (sort
        (map round-requirement seat-requirements)
        seat-requirement-<)
       port))))
