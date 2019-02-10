; This file is a simulation of a flirt detector. The user inputs a sentence
; (from some conversation) and gets back the percentage of the intention
; (flirtation, non flirting affection, self perception...).

#lang racket
(require racket/gui/base)
(require web-server/servlet)
; Provides serve/servlet and happens to provide response/full.
(require web-server/servlet-env)
(require net/sendurl)
(require simple-http)
(require json)
(require rackunit)
(require test-engine/racket-tests)

; ====================================================
;                   API part
; ====================================================
; Variable for accessing code to the API.

; Empty variable to hold the access code given by google api
(define acc-code "")

; Empty variable to hold the authentication key to call the AutoML API
(define auth-key "")

; Client ID given by google IAM system
(define CLIENT-ID
  "953670783310-382k5nb2qdfguunfo3nbvv8a8joqkcm3.apps.googleusercontent.com")

; URL of the link that needs to be send in order to get the access code.
(define URL (string-append "https://accounts.google.com/o/oauth2/auth?scope=https://www.googleapis.com/auth/cloud-platform&response_type=code&access_type=offline&redirect_uri=http://localhost:8000/token/&client_id=" CLIENT-ID))

; http-response: String -> Struct
; Given the content return a struct (given by response/full)
; (struct response/full (code message seconds mime headers body)
(define (http-response content)  ; The 'content' parameter should be a string.
  (response/full
    200                  ; HTTP response code.
    #"OK"                ; HTTP response message.
    (current-seconds)    ; Timestamp.
    TEXT/HTML-MIME-TYPE  ; MIME type for content.
    '()                  ; Additional HTTP headers.
    (list                ; Content (in bytes) to send to the browser.
      (string->bytes/utf-8 content)))
  )
; Test the http response code
; Test for connection code and the output
(check-eq? (response-code (http-response "This is good")) 200)
(check-eq? (procedure? (response-output (http-response "Checking content")))#t)
            

; Initializer for the post request for google API.
(define google-api
  (update-ssl
   (update-host json-requester "www.googleapis.com") #t))


; get-score: HashEQ Option String -> Number.
; Given a Hash map, an Option and a String return the percentage of the chosen category.
(define (get-score pred pay displayName)
  (cond [(string=? displayName  (cdr (first (hash->list (first (hash-ref pred pay))))))
         (cdr (car (hash->list (cdr (second (hash->list (first (hash-ref pred pay))))))))]
        [(string=? displayName (cdr (first (hash->list (second (hash-ref pred pay))))))
         (cdr (car (hash->list (cdr (second (hash->list (second (hash-ref pred pay))))))))]
        [(string=? displayName (cdr (first (hash->list (third (hash-ref pred pay))))))
         (cdr (car (hash->list (cdr (second (hash->list (third (hash-ref pred pay))))))))]
        [(string=? displayName (cdr (first (hash->list (fourth (hash-ref pred pay))))))
         (cdr (car (hash->list (cdr (second (hash->list (fourth (hash-ref pred pay))))))))]
        [(string=? displayName (cdr (first (hash->list (fifth (hash-ref pred pay))))))
         (cdr (car (hash->list (cdr (second (hash->list (fifth (hash-ref pred pay))))))))]
        ))
; Test get-score
; Create a test-predict as a json hashmap. Then test if the function can handle the hashmap for the correct output
(define test-predict
  '#hasheq((payload
          .
          (#hasheq((classification . #hasheq((score . 0.63047427))) (displayName . "flirtation"))
           #hasheq((classification . #hasheq((score . 0.10311453))) (displayName . "sorrow_and_break_up"))
           #hasheq((classification . #hasheq((score . 0.13499533))) (displayName . "self_perception"))
           #hasheq((classification . #hasheq((score . 0.2801268))) (displayName . "non_flirting_affection"))
           #hasheq((classification . #hasheq((score . 0.29289556))) (displayName . "world_perception"))))))
(check-eq? (get-score test-predict 'payload "flirtation") 0.63047427)
(check-eq? (get-score test-predict 'payload "sorrow_and_break_up") 0.10311453)
(check-eq? (get-score test-predict 'payload "self_perception") 0.13499533)



; Initializing the beginning thread. This thread run in the background to make sure that the program is authorized
; This thread will handle the initial step of the OAuth2.0 process: getting the access code
(thread (lambda ()
          (begin
            ; Send initial URL to get the token
            ; String -> Response as a Struct
            ; Enter access code for the database to get 
            (define (response-test code)
              (post
               google-api
               "/oauth2/v4/token"
               #:data (jsexpr->string (hasheq 'client_id
                                              "953670783310-382k5nb2qdfguunfo3nbvv8a8joqkcm3.apps.googleusercontent.com"
                                              'client_secret "VIyH0aSnQ3NcE46YsMZvXtqD"
                                              'redirect_uri "http://localhost:8000/token/"
                                              'grant_type "authorization_code"
                                              ;Change the 'code every hour
                                              'code code))
               ))
            ;Send the URL get the access code
            (send-url URL)
            
            ; get-param->string: Request String -> String.
            ; get the specific argument within the request.
            (define (get-param->string req param)
              (if (eq? #f (bindings-assq (string->bytes/utf-8 param)
                                         (request-bindings/raw req)))
                  ""
                  (bytes->string/utf-8 
                   (binding:form-value 
                    (bindings-assq (string->bytes/utf-8 param)
                                   (request-bindings/raw req))))))

            ; Define values dispatch and generate url which
            ; gets the value from the function call (dispatch-rules ...)
            (define-values (dispatch generate-url)
              (dispatch-rules    
               [("token" (string-arg)) token-page]))

            ; Make a request-handler to dispatch the request
            (define (request-handler request)
              (dispatch request))

            ; Token page: use the request and the token to get the authorization for the code. 
            (define (token-page request token)  ; Notice the additional parameter.
              (set! acc-code (get-param->string request "code")) ; Set the access code
              (set! auth-key (cdr(second (hash->list (json-response-body (response-test acc-code)))))) ; send the access code to get the authorization key.
              (http-response "Got Authorization, return to the program.");display to the browser
              )
            
            ;; Start the server.
            (serve/servlet
             request-handler
             #:launch-browser? #f
             #:quit? #f
             #:listen-ip #f
             #:port 8000
             #:servlet-regexp #rx""))))
; ====================================================
;                   Star diagram part
; ====================================================

; Define class custom-canvas%, inheriting from editor-class%
(define custom-canvas%
  (class editor-canvas%
    ; Define 5 base points of the pentagon.
    (define X1 300)
    (define Y1  50)
    (define X2 157)
    (define Y2 154)
    (define X3 212)
    (define Y3 321)
    (define X4 388)
    (define Y4 321)
    (define X5 443)
    (define Y5 154)
    
    (super-new)
    (inherit get-dc get-width get-height)
    ; initialize 5 new fields of the canvas
    (init-field flirtation)
    (init-field sorrow)
    (init-field self-perception)
    (init-field world-perception)
    (init-field non-flirt)
    ;overiding on-paint method of object custom-canvas to draw the radar chart
    (define/override (on-paint)
      ; get the drawing context of the object
      (define dc (get-dc))

      ; Take the center of the canvas as the center of the radar chart
      (define CENTER-X (/ (get-width) 2))
      (define CENTER-Y (/ (get-height) 2))

      ;erase old drawing to fill in with the new one
      (send dc erase)
      (send dc set-pen "orange" 2 'solid)

      ; Draw the initial pentagon using the pre-define points
      (send dc draw-line X1 Y1 X2 Y2)
      (send dc draw-line X2 Y2 X3 Y3)
      (send dc draw-line X3 Y3 X4 Y4)
      (send dc draw-line X4 Y4 X5 Y5)
      (send dc draw-line X5 Y5 X1 Y1)

      ;Draw Flirtation part
      (send dc set-pen "HotPink" 2 'solid)
      (send dc draw-line CENTER-X CENTER-Y X1 Y1)
      (send dc set-brush "HotPink" 'solid)
      (send dc draw-text (string-append "Flirtation: " (number->string (round (* flirtation 100))) "%") 265 30)
      (send dc draw-ellipse
            (+ CENTER-X (* (- X1 CENTER-X) flirtation))
            (+ CENTER-Y (* (- Y1 CENTER-Y) flirtation)) 4 4)

      ;Draw sorrow and break up part
      (send dc set-pen "LightSkyBlue" 2 'solid)
      (send dc draw-line  CENTER-X CENTER-Y X3 Y3)
      (send dc set-brush "LightSkyBlue" 'solid)
      (send dc draw-text (string-append "Sorrow/breakup: " (number->string (round (* sorrow 100))) "%")  150 330)
      (send dc draw-ellipse
            (+ CENTER-X (* (- X3 CENTER-X) sorrow))
            (+ CENTER-Y (* (- Y3 CENTER-Y) sorrow)) 4 4)

      ;Draw non-flirting affection part
      (send dc set-pen "Crimson" 2 'solid)
      (send dc draw-line  CENTER-X CENTER-Y X2 Y2)
      (send dc set-brush "Crimson" 'solid)
      (send dc draw-text (string-append "Non flirting: " (number->string (round (* non-flirt 100))) "%")  15 145)
      (send dc draw-ellipse
            (+ CENTER-X (* (- X2 CENTER-X) non-flirt))
            (+ CENTER-Y (* (- Y2 CENTER-Y) non-flirt)) 4 4)
      
      ;Draw world-perception part
      (send dc set-pen "LimeGreen" 2 'solid)
      (send dc draw-line  CENTER-X CENTER-Y X4 Y4)
      (send dc set-brush "LimeGreen" 'solid)
      (send dc draw-text (string-append "World perception: " (number->string (round (* world-perception 100))) "%")  340 330)
      (send dc draw-ellipse
            (+ CENTER-X (* (- X4 CENTER-X) world-perception))
            (+ CENTER-Y (* (- Y4 CENTER-Y) world-perception)) 4 4)

      ;Draw self-perception part
      (send dc set-pen "DarkOrchid" 2 'solid)
      (send dc draw-line  CENTER-X CENTER-Y X5 Y5)
      (send dc set-brush "DarkOrchid" 'solid)
      (send dc draw-text (string-append "Self perception " (number->string (round (* self-perception 100))) "%")  460 145)
      (send dc draw-ellipse
            (+ CENTER-X (* (- X5 CENTER-X) self-perception))
            (+ CENTER-Y (* (- Y5 CENTER-Y) self-perception)) 4 4)
      
      ;Draw the complete polygon
      (send dc set-pen "white" 1 'transparent)
      (send dc set-brush "Red" 'hilite)
      (send dc draw-polygon
            (list (cons
                   (+ CENTER-X (* (- X1 CENTER-X) flirtation))
                   (+ CENTER-Y (* (- Y1 CENTER-Y) flirtation))
                   )
                  (cons
                   (+ CENTER-X (* (- X2 CENTER-X) non-flirt))
                   (+ CENTER-Y (* (- Y2 CENTER-Y) non-flirt))
                   )
                  (cons
                   (+ CENTER-X (* (- X3 CENTER-X) sorrow))
                   (+ CENTER-Y (* (- Y3 CENTER-Y) sorrow))
                   )
                  (cons
                   (+ CENTER-X (* (- X4 CENTER-X) world-perception))
                   (+ CENTER-Y (* (- Y4 CENTER-Y) world-perception))
                   )
                  (cons
                   (+ CENTER-X (* (- X5 CENTER-X) self-perception))
                   (+ CENTER-Y (* (- Y5 CENTER-Y) self-perception))
                   )
            )
      )
    )))
; Test the new Object:
; Check if the field of the canvas work
(check-eq? (get-field flirtation (new custom-canvas%
                    [flirtation 1]
                    [sorrow 2]
                    [self-perception 3]
                    [world-perception 4]
                    [non-flirt 5]
                    [parent (new frame% [label "Flirt detector"]
                                 [width 600]
                                 [height 400]
                                 [alignment '(right top)])]
                    [label "output"]
                    [min-width 600]
                    [min-height 400]
                    [vert-margin 10]
                    [horiz-margin 10]
                    [style '(no-hscroll auto-vscroll)]
                    [stretchable-width #t]
                    [stretchable-height #t])) 1)

; ====================================================
;                   GUI window part
; ====================================================
; Make a frame by instantiating the frame% class
(define frame (new frame% [label "Flirt detector"]
                   [width 600]
                   [height 400]
                   [alignment '(right top)]))
 
; Add a text field to the dialog
(define text-input (new text-field%
                        [parent frame]
                        [label "Enter your text here:"]
                        [min-width 150]
                        [min-height 150]
                        [vert-margin 30]
                        [horiz-margin 10]
                        [stretchable-width #t]
                        [stretchable-height #f]
                        [style (list 'single 'multiple 'hscroll)]))

; Make a static text message in the frame.
(define msg (new message%
                 [parent frame]
                 [label "The result of the prediction:"]
                 [vert-margin 2]
                 [horiz-margin 10]))

; Add a horizontal panel to the dialog, with centering for buttons.
; Here should appear the diagram
(define panel (new horizontal-panel%
                   [parent frame]
                   [vert-margin 10]
                   [horiz-margin 10]
                   [alignment '(left bottom)]
                   [stretchable-width #t]
                   [stretchable-height #f]))

; A window inside the same frame which shows the result of the
; prediction.
(define output (new custom-canvas%
                    [flirtation 0]
                    [sorrow 0]
                    [self-perception 0]
                    [world-perception 0]
                    [non-flirt 0]
                    [parent panel]
                    [label "output"]
                    [min-width 600]
                    [min-height 400]
                    [vert-margin 10]
                    [horiz-margin 10]
                    [style '(no-hscroll auto-vscroll)]
                    [stretchable-width #t]
                    [stretchable-height #t]))

; Button to start the prediction of the text.
(define predict-button (new button%
                            [parent frame]
                            [label "Predict"]
                            [vert-margin 10]
                            [horiz-margin 20]
                            [callback (lambda (b e) (on-click-predict-button b e))]
                            ))

; ====================================================
;                   Event Handlers
; ====================================================
; Void function
; Procedure: On the prediction button clicked, the event handler will call the API for prediction,
; receive the prediction, then modify the output object (which is a new custom-canvas) so that
; the canvas can display the result.
; When 
; On-click handle. 
(define (on-click-predict-button button event)
  (define input (send text-input get-value))
  (cond [(eq? input "") (display "No input given, please enter the conversation you want to analyze.")]
        [else (begin
                (define auth (string-append "Authorization: Bearer " auth-key))
                (define content-type "Content-Type: application/json")
                (define auto-ml-api
                  (update-headers
                   (update-ssl
                    (update-host json-requester "automl.googleapis.com") #t)
                   (list auth content-type)
                   )
                  )
                (define data-send
                  (jsexpr->string (hasheq 'payload
                                          (hasheq 'textSnippet
                                                  (hasheq 'content input
                                                          'mime_type "text/plain")))))
                (define predict
                  (json-response-body (post
                                       auto-ml-api "/v1beta1/projects/flirtdetector/locations/us-central1/models/TCN2255869835756317386:predict"
                                       #:data data-send)))
                
                (define flirt-score (get-score predict 'payload "flirtation"))
                (dynamic-set-field! 'flirtation output flirt-score)
  
                (define sorrow-score (get-score predict 'payload "sorrow_and_break_up"))
                (dynamic-set-field! 'sorrow output sorrow-score)
  
                (define self-score (get-score predict 'payload "self_perception"))
                (dynamic-set-field! 'self-perception output self-score)

                (define world-score (get-score predict 'payload "world_perception"))
                (dynamic-set-field! 'world-perception output world-score)

                (define non-score  (get-score predict 'payload "non_flirting_affection"))
                (dynamic-set-field! 'non-flirt output non-score)
                (send output on-paint))]))
; The event handler cannot be test since the process requires a working token.

; Show the dialog
(send frame show #t)