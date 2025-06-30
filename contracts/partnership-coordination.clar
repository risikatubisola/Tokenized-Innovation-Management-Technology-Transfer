;; Partnership Coordination Contract
;; Coordinates transfer partnerships

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_PARTNERSHIP_NOT_FOUND (err u401))
(define-constant ERR_INVALID_TERMS (err u402))
(define-constant ERR_ALREADY_SIGNED (err u403))

;; Data maps
(define-map partnerships
  { partnership-id: uint }
  {
    tech-id: uint,
    coordinator: principal,
    partner-organization: (string-ascii 100),
    partner-contact: principal,
    partnership-type: (string-ascii 50),
    terms: (string-ascii 500),
    revenue-split: uint,
    duration-months: uint,
    created-date: uint,
    status: (string-ascii 20),
    coordinator-signed: bool,
    partner-signed: bool
  }
)

(define-map partnership-agreements
  { partnership-id: uint }
  {
    ip-licensing-terms: (string-ascii 300),
    exclusivity-clause: bool,
    territory-restrictions: (string-ascii 200),
    performance-metrics: (string-ascii 200),
    termination-conditions: (string-ascii 200)
  }
)

;; Data variables
(define-data-var next-partnership-id uint u1)
(define-data-var total-partnerships uint u0)

;; Public functions
(define-public (create-partnership
  (tech-id uint)
  (partner-organization (string-ascii 100))
  (partner-contact principal)
  (partnership-type (string-ascii 50))
  (terms (string-ascii 500))
  (revenue-split uint)
  (duration-months uint)
)
  (let (
    (partnership-id (var-get next-partnership-id))
  )
    (asserts! (<= revenue-split u100) ERR_INVALID_TERMS)
    (asserts! (> duration-months u0) ERR_INVALID_TERMS)

    (map-set partnerships
      { partnership-id: partnership-id }
      {
        tech-id: tech-id,
        coordinator: tx-sender,
        partner-organization: partner-organization,
        partner-contact: partner-contact,
        partnership-type: partnership-type,
        terms: terms,
        revenue-split: revenue-split,
        duration-months: duration-months,
        created-date: stacks-block-height,
        status: "pending",
        coordinator-signed: true,
        partner-signed: false
      }
    )

    (var-set next-partnership-id (+ partnership-id u1))
    (var-set total-partnerships (+ (var-get total-partnerships) u1))
    (ok partnership-id)
  )
)

(define-public (add-partnership-agreement
  (partnership-id uint)
  (ip-licensing-terms (string-ascii 300))
  (exclusivity-clause bool)
  (territory-restrictions (string-ascii 200))
  (performance-metrics (string-ascii 200))
  (termination-conditions (string-ascii 200))
)
  (let (
    (partnership-data (unwrap! (map-get? partnerships { partnership-id: partnership-id }) ERR_PARTNERSHIP_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get coordinator partnership-data)) ERR_UNAUTHORIZED)

    (map-set partnership-agreements
      { partnership-id: partnership-id }
      {
        ip-licensing-terms: ip-licensing-terms,
        exclusivity-clause: exclusivity-clause,
        territory-restrictions: territory-restrictions,
        performance-metrics: performance-metrics,
        termination-conditions: termination-conditions
      }
    )

    (ok true)
  )
)

(define-public (sign-partnership (partnership-id uint))
  (let (
    (partnership-data (unwrap! (map-get? partnerships { partnership-id: partnership-id }) ERR_PARTNERSHIP_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get partner-contact partnership-data)) ERR_UNAUTHORIZED)
    (asserts! (not (get partner-signed partnership-data)) ERR_ALREADY_SIGNED)

    (map-set partnerships
      { partnership-id: partnership-id }
      (merge partnership-data {
        partner-signed: true,
        status: "active"
      })
    )

    (ok true)
  )
)

(define-public (update-partnership-status (partnership-id uint) (new-status (string-ascii 20)))
  (let (
    (partnership-data (unwrap! (map-get? partnerships { partnership-id: partnership-id }) ERR_PARTNERSHIP_NOT_FOUND))
  )
    (asserts! (or (is-eq tx-sender (get coordinator partnership-data))
                  (is-eq tx-sender (get partner-contact partnership-data))) ERR_UNAUTHORIZED)

    (map-set partnerships
      { partnership-id: partnership-id }
      (merge partnership-data { status: new-status })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-partnership (partnership-id uint))
  (map-get? partnerships { partnership-id: partnership-id })
)

(define-read-only (get-partnership-agreement (partnership-id uint))
  (map-get? partnership-agreements { partnership-id: partnership-id })
)

(define-read-only (is-partnership-active (partnership-id uint))
  (match (map-get? partnerships { partnership-id: partnership-id })
    partnership-data (and (get coordinator-signed partnership-data) (get partner-signed partnership-data))
    false
  )
)

(define-read-only (get-total-partnerships)
  (var-get total-partnerships)
)
