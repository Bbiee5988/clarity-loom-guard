;; LoomGuard - Textile Innovation Management System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-expired-license (err u104))

;; Data Variables
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

;; Private Functions
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

;; Public Functions
(define-public (register-innovation 
    (name (string-utf8 100))
    (description (string-utf8 500))
    (hash (buff 32))
    (royalty-rate uint))
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
            (ok new-id)
        )
    )
)

(define-public (pay-royalty
    (innovation-id uint)
    (amount uint))
    (let ((innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) err-not-found))
          (license (unwrap! (map-get? licenses {innovation-id: innovation-id, licensee: tx-sender}) err-not-found))
          (new-payment-id (+ (var-get payment-counter) u1)))
        (if (and (is-license-valid license) (>= amount u0))
            (begin
                (map-set licenses
                    {innovation-id: innovation-id, licensee: tx-sender}
                    (merge license {royalty-paid: (+ (get royalty-paid license) amount)})
                )
                (map-set royalty-payments
                    {payment-id: new-payment-id}
                    {
                        innovation-id: innovation-id,
                        licensee: tx-sender,
                        amount: amount,
                        timestamp: block-height
                    }
                )
                (var-set payment-counter new-payment-id)
                (ok true)
            )
            (if (not (is-license-valid license))
                err-expired-license
                err-invalid-amount)
        )
    )
)

[rest of contract remains unchanged]
