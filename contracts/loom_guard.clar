;; LoomGuard - Textile Innovation Management System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-map innovations
    { innovation-id: uint }
    {
        owner: principal,
        name: (string-utf8 100),
        description: (string-utf8 500),
        timestamp: uint,
        hash: (buff 32),
        status: (string-ascii 20)
    }
)

(define-map licenses
    { innovation-id: uint, licensee: principal }
    {
        expires: uint,
        terms: (string-utf8 200),
        active: bool
    }
)

(define-data-var innovation-counter uint u0)

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
    (hash (buff 32)))
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
                    status: "active"
                }
            )
            (var-set innovation-counter new-id)
            (ok new-id)
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
                    active: true
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

(define-read-only (verify-ownership (innovation-id uint) (owner principal))
    (let ((innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) (err false))))
        (ok (is-eq (get owner innovation) owner))
    )
)