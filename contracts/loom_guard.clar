;; LoomGuard - Textile Innovation Management System
;; Version: 1.1.0
;; Security and Events Enhancement

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-expired-license (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-contract-paused (err u106))

;; Validation Constants
(define-constant min-royalty-rate u0)
(define-constant max-royalty-rate u10000) ;; 100% = 10000 basis points

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var contract-owner-address principal tx-sender)

;; Maps (Original maps remain unchanged)
(define-map innovations
    { innovation-id: uint }
    {
        owner: principal,
        name: (string-utf8 100),
        description: (string-utf8 500),
        timestamp: uint,
        hash: (buff 32),
        status: (string-ascii 20),
        royalty-rate: uint
    }
)

(define-map licenses
    { innovation-id: uint, licensee: principal }
    {
        expires: uint,
        terms: (string-utf8 200),
        active: bool,
        royalty-paid: uint
    }
)

(define-map royalty-payments
    { payment-id: uint }
    {
        innovation-id: uint,
        licensee: principal,
        amount: uint,
        timestamp: uint
    }
)

(define-data-var innovation-counter uint u0)
(define-data-var payment-counter uint u0)

;; Events
(define-data-var last-event-id uint u0)

(define-map events 
    { event-id: uint }
    {
        event-type: (string-ascii 20),
        innovation-id: uint,
        principal: principal,
        data: (optional (string-utf8 200))
    }
)

;; Private Functions
(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner-address))
)

(define-private (assert-not-paused)
    (asserts! (not (var-get contract-paused)) err-contract-paused)
)

(define-private (is-owner (innovation-id uint))
    (let ((innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) (err false))))
        (is-eq (get owner innovation) tx-sender)
    )
)

(define-private (is-license-valid (license { expires: uint, terms: (string-utf8 200), active: bool, royalty-paid: uint }))
    (and 
        (get active license)
        (> (get expires license) block-height)
    )
)

(define-private (emit-event (event-type (string-ascii 20)) (innovation-id uint) (principal principal) (data (optional (string-utf8 200))))
    (let ((new-event-id (+ (var-get last-event-id) u1)))
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

;; Public Functions
(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (var-set contract-paused (not (var-get contract-paused))))
    )
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (var-set contract-owner-address new-owner))
    )
)

(define-public (register-innovation 
    (name (string-utf8 100))
    (description (string-utf8 500))
    (hash (buff 32))
    (royalty-rate uint))
    (begin
        (assert-not-paused)
        (asserts! (>= royalty-rate min-royalty-rate) err-invalid-input)
        (asserts! (<= royalty-rate max-royalty-rate) err-invalid-input)
        (asserts! (not (is-eq name "")) err-invalid-input)
        (let
            ((new-id (+ (var-get innovation-counter) u1)))
            (begin
                (map-set innovations
                    {innovation-id: new-id}
                    {
                        owner: tx-sender,
                        name: name,
                        description: description,
                        timestamp: block-height,
                        hash: hash,
                        status: "active",
                        royalty-rate: royalty-rate
                    }
                )
                (var-set innovation-counter new-id)
                (emit-event "INNOVATION_REG" new-id tx-sender none)
                (ok new-id)
            )
        )
    )
)

;; [Rest of the original functions remain unchanged but with assert-not-paused added]
