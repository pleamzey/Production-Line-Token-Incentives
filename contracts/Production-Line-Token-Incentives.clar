(define-fungible-token efficiency-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-worker (err u101))
(define-constant err-invalid-kpi (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-worker-not-found (err u104))
(define-constant err-kpi-not-found (err u105))
(define-constant err-invalid-reward (err u106))
(define-constant err-already-claimed (err u107))
(define-constant err-not-verified (err u108))

(define-data-var total-workers uint u0)
(define-data-var total-kpis uint u0)
(define-data-var reward-pool uint u0)

(define-map workers
  { worker-id: uint }
  {
    address: principal,
    total-earned: uint,
    active: bool,
    registration-block: uint
  }
)

(define-map worker-addresses
  { address: principal }
  { worker-id: uint }
)

(define-map kpis
  { kpi-id: uint }
  {
    name: (string-ascii 50),
    reward-amount: uint,
    verification-threshold: uint,
    active: bool,
    creator: principal
  }
)

(define-map worker-kpi-achievements
  { worker-id: uint, kpi-id: uint, achievement-block: uint }
  {
    score: uint,
    verified: bool,
    claimed: bool,
    verifier: (optional principal)
  }
)

(define-map daily-worker-stats
  { worker-id: uint, day: uint }
  {
    efficiency-score: uint,
    quality-score: uint,
    tasks-completed: uint,
    rewards-earned: uint
  }
)

(define-read-only (get-worker (worker-id uint))
  (map-get? workers { worker-id: worker-id })
)

(define-read-only (get-worker-by-address (address principal))
  (match (map-get? worker-addresses { address: address })
    worker-entry (map-get? workers { worker-id: (get worker-id worker-entry) })
    none
  )
)

(define-read-only (get-kpi (kpi-id uint))
  (map-get? kpis { kpi-id: kpi-id })
)

(define-read-only (get-achievement (worker-id uint) (kpi-id uint) (achievement-block uint))
  (map-get? worker-kpi-achievements 
    { worker-id: worker-id, kpi-id: kpi-id, achievement-block: achievement-block }
  )
)

(define-read-only (get-daily-stats (worker-id uint) (day uint))
  (map-get? daily-worker-stats { worker-id: worker-id, day: day })
)

(define-read-only (get-total-workers)
  (var-get total-workers)
)

(define-read-only (get-total-kpis)
  (var-get total-kpis)
)

(define-read-only (get-reward-pool)
  (var-get reward-pool)
)

(define-read-only (get-token-balance (address principal))
  (ft-get-balance efficiency-token address)
)

(define-public (register-worker (worker-address principal))
  (let ((new-worker-id (+ (var-get total-workers) u1)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? worker-addresses { address: worker-address })) err-invalid-worker)
    
    (map-set workers
      { worker-id: new-worker-id }
      {
        address: worker-address,
        total-earned: u0,
        active: true,
        registration-block: stacks-block-height
      }
    )
    
    (map-set worker-addresses
      { address: worker-address }
      { worker-id: new-worker-id }
    )
    
    (var-set total-workers new-worker-id)
    (ok new-worker-id)
  )
)

(define-public (create-kpi (name (string-ascii 50)) (reward-amount uint) (verification-threshold uint))
  (let ((new-kpi-id (+ (var-get total-kpis) u1)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> reward-amount u0) err-invalid-reward)
    (asserts! (> verification-threshold u0) err-invalid-kpi)
    
    (map-set kpis
      { kpi-id: new-kpi-id }
      {
        name: name,
        reward-amount: reward-amount,
        verification-threshold: verification-threshold,
        active: true,
        creator: tx-sender
      }
    )
    
    (var-set total-kpis new-kpi-id)
    (ok new-kpi-id)
  )
)

(define-public (record-achievement (worker-id uint) (kpi-id uint) (score uint))
  (let (
    (worker (unwrap! (map-get? workers { worker-id: worker-id }) err-worker-not-found))
    (kpi (unwrap! (map-get? kpis { kpi-id: kpi-id }) err-kpi-not-found))
    (current-block stacks-block-height)
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get active worker) err-invalid-worker)
    (asserts! (get active kpi) err-invalid-kpi)
    (asserts! (>= score (get verification-threshold kpi)) err-invalid-kpi)
    
    (map-set worker-kpi-achievements
      { worker-id: worker-id, kpi-id: kpi-id, achievement-block: current-block }
      {
        score: score,
        verified: false,
        claimed: false,
        verifier: none
      }
    )
    
    (ok true)
  )
)

(define-public (verify-achievement (worker-id uint) (kpi-id uint) (achievement-block uint))
  (let (
    (achievement (unwrap! (map-get? worker-kpi-achievements 
      { worker-id: worker-id, kpi-id: kpi-id, achievement-block: achievement-block }) err-kpi-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (get verified achievement)) err-already-claimed)
    
    (map-set worker-kpi-achievements
      { worker-id: worker-id, kpi-id: kpi-id, achievement-block: achievement-block }
      (merge achievement { verified: true, verifier: (some tx-sender) })
    )
    
    (ok true)
  )
)

(define-public (claim-reward (worker-id uint) (kpi-id uint) (achievement-block uint))
  (let (
    (worker (unwrap! (map-get? workers { worker-id: worker-id }) err-worker-not-found))
    (kpi (unwrap! (map-get? kpis { kpi-id: kpi-id }) err-kpi-not-found))
    (achievement (unwrap! (map-get? worker-kpi-achievements 
      { worker-id: worker-id, kpi-id: kpi-id, achievement-block: achievement-block }) err-kpi-not-found))
    (reward-amount (get reward-amount kpi))
  )
    (asserts! (is-eq tx-sender (get address worker)) err-invalid-worker)
    (asserts! (get verified achievement) err-not-verified)
    (asserts! (not (get claimed achievement)) err-already-claimed)
    (asserts! (>= (var-get reward-pool) reward-amount) err-insufficient-balance)
    
    (try! (ft-mint? efficiency-token reward-amount (get address worker)))
    
    (map-set worker-kpi-achievements
      { worker-id: worker-id, kpi-id: kpi-id, achievement-block: achievement-block }
      (merge achievement { claimed: true })
    )
    
    (map-set workers
      { worker-id: worker-id }
      (merge worker { total-earned: (+ (get total-earned worker) reward-amount) })
    )
    
    (var-set reward-pool (- (var-get reward-pool) reward-amount))
    (ok reward-amount)
  )
)

(define-public (update-daily-stats (worker-id uint) (efficiency-score uint) (quality-score uint) (tasks-completed uint))
  (let (
    (worker (unwrap! (map-get? workers { worker-id: worker-id }) err-worker-not-found))
    (current-day (/ stacks-block-height u144))
    (efficiency-bonus (if (>= efficiency-score u80) u10 u0))
    (quality-bonus (if (>= quality-score u90) u15 u0))
    (productivity-bonus (if (>= tasks-completed u10) u5 u0))
    (total-bonus (+ efficiency-bonus quality-bonus productivity-bonus))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get active worker) err-invalid-worker)
    
    (map-set daily-worker-stats
      { worker-id: worker-id, day: current-day }
      {
        efficiency-score: efficiency-score,
        quality-score: quality-score,
        tasks-completed: tasks-completed,
        rewards-earned: total-bonus
      }
    )
    
    (if (> total-bonus u0)
      (begin
        (try! (ft-mint? efficiency-token total-bonus (get address worker)))
        (map-set workers
          { worker-id: worker-id }
          (merge worker { total-earned: (+ (get total-earned worker) total-bonus) })
        )
        (ok total-bonus)
      )
      (ok u0)
    )
  )
)

(define-public (fund-reward-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-reward)
    
    (var-set reward-pool (+ (var-get reward-pool) amount))
    (ok true)
  )
)

(define-public (deactivate-worker (worker-id uint))
  (let ((worker (unwrap! (map-get? workers { worker-id: worker-id }) err-worker-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set workers
      { worker-id: worker-id }
      (merge worker { active: false })
    )
    
    (ok true)
  )
)

(define-public (deactivate-kpi (kpi-id uint))
  (let ((kpi (unwrap! (map-get? kpis { kpi-id: kpi-id }) err-kpi-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set kpis
      { kpi-id: kpi-id }
      (merge kpi { active: false })
    )
    
    (ok true)
  )
)

(define-public (transfer-tokens (recipient principal) (amount uint))
  (ft-transfer? efficiency-token amount tx-sender recipient)
)

(define-read-only (calculate-worker-efficiency (worker-id uint) (days-back uint))
  (let (
    (current-day (/ stacks-block-height u144))
    (start-day (if (>= current-day days-back) (- current-day days-back) u0))
  )
    (fold calculate-daily-efficiency 
      (list start-day (+ start-day u1) (+ start-day u2) (+ start-day u3) (+ start-day u4) (+ start-day u5) (+ start-day u6))
      { worker-id: worker-id, total-efficiency: u0, days-counted: u0 }
    )
  )
)

(define-private (calculate-daily-efficiency (day uint) (acc { worker-id: uint, total-efficiency: uint, days-counted: uint }))
  (match (map-get? daily-worker-stats { worker-id: (get worker-id acc), day: day })
    stats {
      worker-id: (get worker-id acc),
      total-efficiency: (+ (get total-efficiency acc) (get efficiency-score stats)),
      days-counted: (+ (get days-counted acc) u1)
    }
    acc
  )
)

(define-read-only (get-worker-ranking (worker-id uint))
  (let ((worker (unwrap! (map-get? workers { worker-id: worker-id }) u0)))
    (get total-earned worker)
  )
)

(define-public (batch-verify-achievements (achievements (list 20 { worker-id: uint, kpi-id: uint, achievement-block: uint })))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map verify-single-achievement achievements))
  )
)

(define-private (verify-single-achievement (achievement { worker-id: uint, kpi-id: uint, achievement-block: uint }))
  (match (map-get? worker-kpi-achievements achievement)
    existing-achievement
      (begin
        (map-set worker-kpi-achievements
          achievement
          (merge existing-achievement { verified: true, verifier: (some tx-sender) })
        )
        true
      )
    false
  )
)

(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok true)
  )
)

(define-read-only (get-contract-info)
  {
    total-workers: (var-get total-workers),
    total-kpis: (var-get total-kpis),
    reward-pool: (var-get reward-pool),
    contract-owner: contract-owner
  }
)

(define-read-only (get-worker-performance-summary (worker-id uint))
  (let (
    (worker (unwrap! (map-get? workers { worker-id: worker-id }) (err u404)))
    (efficiency-data (calculate-worker-efficiency worker-id u7))
    (avg-efficiency (if (> (get days-counted efficiency-data) u0)
                      (/ (get total-efficiency efficiency-data) (get days-counted efficiency-data))
                      u0))
  )
    (ok {
      worker-info: worker,
      avg-efficiency-7days: avg-efficiency,
      total-earned: (get total-earned worker),
      active-status: (get active worker)
    })
  )
)
