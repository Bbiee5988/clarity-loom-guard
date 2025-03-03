;; LoomGuard - Textile Innovation Management System
;; Version: 1.1.1
;; Security and Events Enhancement with Fixes

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-expired-license (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-contract-paused (err u106))
(define-constant err-event-limit-reached (err u107))

;; Validation Constants
(define-constant min-royalty-rate u0)
(define-constant max-royalty-rate u10000)
(define-constant max-events u1000)

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var contract-owner-address principal tx-sender)

;; [Previous maps remain unchanged]

;; Enhanced Private Functions
(define-private (is-owner (innovation-id uint))
    (match (map-get? innovations {innovation-id: innovation-id})
        innovation (is-eq (get owner innovation) tx-sender)
        false
    )
)

(define-private (emit-event (event-type (string-ascii 20)) (innovation-id uint) (principal principal) (data (optional (string-utf8 200))))
    (let 
        (
            (new-event-id (+ (var-get last-event-id) u1))
            (current-events (var-get last-event-id))
        )
        (asserts! (< current-events max-events) err-event-limit-reached)
        (begin
            (map-set events
                { event-id: new-event-id }
                {
                    event-type: event-type,
                    innovation-id: innovation-id,
                    principal: principal,
                    data: data
                }
            )
            (var-set last-event-id new-event-id)
            (ok new-event-id)
        )
    )
)

;; [Rest of the contract remains unchanged]
