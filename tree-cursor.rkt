#lang racket/base
(require racket/list)

;; Tree cursor library.
;; Offers functional views, traversals of the DOM and other tree-like structures.
;; See Functional Pearl: The Zipper, by G\'erard Huet
;; J. Functional Programming 7 (5): 549--554 Sepember 1997

(struct cursor (parent node prevs nexts open-f close-f atomic?-f))


;; Returns true if the cursor is focused on an atomic element.
(define (cursor-atomic? a-cursor)
  ((cursor-atomic?-f a-cursor) (cursor-node a-cursor)))


;; Returns true if the cursor can be navigated downward.
(define (cursor-down? a-cursor)
  (and (not ((cursor-atomic?-f a-cursor) (cursor-node a-cursor)))
       (not (empty? (length ((cursor-open-f a-cursor) (cursor-node a-cursor)))))))
          

(define (cursor-down a-cursor)
  (unless (not ((cursor-atomic?-f a-cursor) (cursor-node a-cursor)))
    (error 'cursor-down "down of atomic element"))
  
  (define opened ((cursor-open-f a-cursor) (cursor-node a-cursor)))
  
  (unless (not (empty? (length opened)))
    (error 'cursor-down "down of element with no children"))
  
  (cursor-refresh a-cursor
                  a-cursor
                  (first opened)
                  '()
                  (rest opened)))



;; Returns true if the cursor can be navigated upward.
(define (cursor-up? a-cursor)
  (not (eq? (cursor-parent a-cursor) #f)))

(define (cursor-up a-cursor)
  (define parent (cursor-parent a-cursor))
  (cursor-refresh a-cursor
                  (cursor-parent parent)
                  ((cursor-close-f a-cursor) 
                   (cursor-node parent)
                   (append/rev (cursor-prevs a-cursor) 
                               (cursor-nexts a-cursor)))
                  (cursor-prevs parent)
                  (cursor-nexts parent)))




(define (cursor-left? a-cursor)
  (not (empty? (cursor-prevs a-cursor))))

(define (cursor-left a-cursor)
  (define prevs (cursor-prevs a-cursor))
  (when (empty? prevs)
    (error 'cursor-left "nothing left of cursor"))
  (cursor-refresh a-cursor
                  (cursor-parent a-cursor)
                  (first prevs)
                  (rest prevs)
                  (cons (cursor-node a-cursor) (cursor-nexts a-cursor))))



(define (cursor-right? a-cursor)
  (not (empty? (cursor-nexts a-cursor))))


(define (cursor-right a-cursor)
  (define nexts (cursor-nexts a-cursor))
  (when (empty? nexts)
    (error 'cursor-right "nothing right of cursor"))
  (cursor-refresh a-cursor
                  (cursor-parent a-cursor)
                  (first nexts)
                  (cons (cursor-node a-cursor)
                        (cursor-prevs a-cursor))
                  (rest nexts)))



(define (cursor-succ a-cursor)
  (cond
    [(cursor-down? a-cursor)
     (cursor-down a-cursor)]
    [(cursor-right? a-cursor)
     (cursor-right a-cursor)]
    [else
     (let loop ([n a-cursor])
       (let ([n (cursor-up a-cursor)])
         (cond
           [(cursor-right? n)
            (cursor-right n)]
           [else
            (loop n)])))]))


(define (cursor-pred a-cursor)
  (cond
    [(cursor-left? a-cursor)
     (define n (cursor-left a-cursor))
     (let outerloop ([n n])
       (cond
         [(cursor-down? n)
          (let innerloop ([n (cursor-down n)])
            (cond
              [(cursor-right? n)
               (innerloop (cursor-right n))]
              [else
               (outerloop n)]))]
         [else
          n]))]
    [else
     (cursor-up a-cursor)]))



;;;;;;;;;;;;;;;;;;;;;;



;; Append the reverse of elts onto the front of lst.
(define (append/rev elts lst)
  (cond
    [(empty? elts)
     lst]
    [else
     (append/rev (rest elts)
                 (cons (first elts) lst))]))


;; Helper for making new cursors with the same implementation functions.
(define (cursor-refresh a-cursor parent node prevs nexts)
  (cursor parent node prevs nexts
          (cursor-open-f a-cursor) (cursor-close-f a-cursor) (cursor-atomic?-f a-cursor)))