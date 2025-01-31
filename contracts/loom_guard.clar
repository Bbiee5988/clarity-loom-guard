;; LoomGuard - Textile Innovation Management System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))

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
        (if (and (get active license) (>= amount u0))
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
            err-invalid-amount
        )
    )
)

(define-public (transfer-ownership 
    (innovation-id uint)
    (new-owner principal))
    (if (is-owner innovation-id)
        (begin
            (map-set innovations
                {innovation-id: innovation-id}
                (merge (unwrap! (map-get? innovations {innovation-id: innovation-id}) err-not-found)
                    {owner: new-owner})
            )
            (ok true)
        )
        err-unauthorized
    )
)

(define-public (grant-license 
    (innovation-id uint)
    (licensee principal)
    (expires uint)
    (terms (string-utf8 200)))
    (if (is-owner innovation-id)
        (begin
            (map-set licenses
                {innovation-id: innovation-id, licensee: licensee}
                {
                    expires: expires,
                    terms: terms,
                    active: true,
                    royalty-paid: u0
                }
            )
            (ok true)
        )
        err-unauthorized
    )
)

;; Read-only Functions
(define-read-only (get-innovation (innovation-id uint))
    (ok (map-get? innovations {innovation-id: innovation-id}))
)

(define-read-only (get-license (innovation-id uint) (licensee principal))
    (ok (map-get? licenses {innovation-id: innovation-id, licensee: licensee}))
)

(define-read-only (get-royalty-payments (innovation-id uint))
    (ok (map-get? royalty-payments {payment-id: innovation-id}))
)

(define-read-only (verify-ownership (innovation-id uint) (owner principal))
    (let ((innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) (err false))))
        (ok (is-eq (get owner innovation) owner))
    )
)
