#lang racket
(require racket/gui)

;;; GUI

(define custom-canvas%
  (class canvas%
    (inherit get-dc get-width get-height)
    (define/override (on-paint)
      (define dc (get-dc))
      (send dc set-brush "green" 'solid)
      (send dc set-pen "blue" 5 'solid)
      (send dc draw-rectangle 0 50 150 50)
      (send dc set-pen "red" 15 'solid)
      (send dc draw-line 0 0 30 30)
      (send dc draw-line 0 30 30 0))
    (super-new)))

;; The frame holds either a start-panel or a game-panel
(define the-frame (new frame% [label "A frame"] [min-width 200] [min-height 200]))

;; The start-panel contains a start button
(define (make-start-panel)
  (define start-panel  (new panel%  [parent the-frame]))
  (define start-button (new button% [parent start-panel] [label "Start"]
                            [callback (λ (b e) (on-start-button b e))]))
  start-panel)

;; The game-panel contains a canvas
(define (make-game-panel)
  (define game-panel   (new panel%  [parent the-frame]))  ; will be set to the-frame later
  
  (define game-canvas  (new custom-canvas%
                            [parent game-panel]
                            [min-width 200]
                            [min-height 200]
                            ))
  
  
  game-panel)

;;; Event Handlers

(define (on-start-button button event)
  (send the-frame begin-container-sequence)
  (send the-frame delete-child the-start-panel)
  (make-game-panel)
  (send the-frame end-container-sequence))

;;; Begin Program
(define the-start-panel (make-start-panel))
(send the-frame show #t)