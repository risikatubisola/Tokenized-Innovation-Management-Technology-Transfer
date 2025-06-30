;; Commercialization Planning Contract
;; Plans technology commercialization

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_PLAN_NOT_FOUND (err u301))
(define-constant ERR_INVALID_TIMELINE (err u302))
(define-constant ERR_INVALID_BUDGET (err u303))

;; Data maps
(define-map commercialization-plans
  { plan-id: uint }
  {
    tech-id: uint,
    coordinator: principal,
    target-market: (string-ascii 100),
    go-to-market-strategy: (string-ascii 300),
    timeline-months: uint,
    estimated-budget: uint,
    revenue-projections: uint,
    risk-assessment: (string-ascii 200),
    created-date: uint,
    status: (string-ascii 20)
  }
)

(define-map plan-milestones
  { plan-id: uint, milestone-id: uint }
  {
    description: (string-ascii 150),
    target-date: uint,
    budget-allocation: uint,
    completed: bool,
    completion-date: uint
  }
)

;; Data variables
(define-data-var next-plan-id uint u1)
(define-data-var total-plans uint u0)

;; Public functions
(define-public (create-commercialization-plan
  (tech-id uint)
  (target-market (string-ascii 100))
  (go-to-market-strategy (string-ascii 300))
  (timeline-months uint)
  (estimated-budget uint)
  (revenue-projections uint)
  (risk-assessment (string-ascii 200))
)
  (let (
    (plan-id (var-get next-plan-id))
  )
    (asserts! (> timeline-months u0) ERR_INVALID_TIMELINE)
    (asserts! (> estimated-budget u0) ERR_INVALID_BUDGET)

    (map-set commercialization-plans
      { plan-id: plan-id }
      {
        tech-id: tech-id,
        coordinator: tx-sender,
        target-market: target-market,
        go-to-market-strategy: go-to-market-strategy,
        timeline-months: timeline-months,
        estimated-budget: estimated-budget,
        revenue-projections: revenue-projections,
        risk-assessment: risk-assessment,
        created-date: block-height,
        status: "draft"
      }
    )

    (var-set next-plan-id (+ plan-id u1))
    (var-set total-plans (+ (var-get total-plans) u1))
    (ok plan-id)
  )
)

(define-public (add-milestone
  (plan-id uint)
  (milestone-id uint)
  (description (string-ascii 150))
  (target-date uint)
  (budget-allocation uint)
)
  (let (
    (plan-data (unwrap! (map-get? commercialization-plans { plan-id: plan-id }) ERR_PLAN_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get coordinator plan-data)) ERR_UNAUTHORIZED)

    (map-set plan-milestones
      { plan-id: plan-id, milestone-id: milestone-id }
      {
        description: description,
        target-date: target-date,
        budget-allocation: budget-allocation,
        completed: false,
        completion-date: u0
      }
    )

    (ok true)
  )
)

(define-public (complete-milestone (plan-id uint) (milestone-id uint))
  (let (
    (plan-data (unwrap! (map-get? commercialization-plans { plan-id: plan-id }) ERR_PLAN_NOT_FOUND))
    (milestone-data (unwrap! (map-get? plan-milestones { plan-id: plan-id, milestone-id: milestone-id }) ERR_PLAN_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get coordinator plan-data)) ERR_UNAUTHORIZED)

    (map-set plan-milestones
      { plan-id: plan-id, milestone-id: milestone-id }
      (merge milestone-data {
        completed: true,
        completion-date: block-height
      })
    )

    (ok true)
  )
)

(define-public (update-plan-status (plan-id uint) (new-status (string-ascii 20)))
  (let (
    (plan-data (unwrap! (map-get? commercialization-plans { plan-id: plan-id }) ERR_PLAN_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get coordinator plan-data)) ERR_UNAUTHORIZED)

    (map-set commercialization-plans
      { plan-id: plan-id }
      (merge plan-data { status: new-status })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-commercialization-plan (plan-id uint))
  (map-get? commercialization-plans { plan-id: plan-id })
)

(define-read-only (get-milestone (plan-id uint) (milestone-id uint))
  (map-get? plan-milestones { plan-id: plan-id, milestone-id: milestone-id })
)

(define-read-only (get-total-plans)
  (var-get total-plans)
)
