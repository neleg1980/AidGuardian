
;; AidGuardian: Decentralized Aid Distribution Protocol
;; A transparent and equitable aid distribution management system

;; Define NFT Trait
(define-trait nft-trait
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response principal uint))
        (get-last-token-id () (response uint uint))
        (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
    )
)

;; Constants
(define-constant guardian-admin tx-sender)
(define-constant min-contribution-amount u100000)
(define-constant consensus-threshold u75)
(define-constant nft-base-uri "ipfs://aidguardian/metadata/")
(define-constant validation-requirement u3)

;; Error Constants
(define-constant err-access-denied (err u100))
(define-constant err-crisis-inactive (err u101))
(define-constant err-insufficient-funds (err u102))
(define-constant err-invalid-contribution (err u103))
(define-constant err-aid-plan-executed (err u104))
(define-constant err-token-transfer-error (err u105))
(define-constant err-not-nft-owner (err u106))
(define-constant err-nft-nonexistent (err u107))
(define-constant err-beneficiary-exists (err u108))
(define-constant err-invalid-proof (err u109))
(define-constant err-unvalidated-user (err u110))

;; Data Variables
(define-data-var total-aid-pool uint u0)
(define-data-var current-crisis-index uint u0)
(define-data-var last-guardian-id uint u0)
(define-data-var last-beneficiary-index uint u0)

;; Data Maps
(define-map contributors 
    principal 
    {total-aid: uint, 
     voting-power: uint, 
     guardian-tokens: uint})

(define-map crisis-registry 
    uint 
    {crisis-name: (string-ascii 64), 
     urgency-level: uint, 
     aid-needed: uint, 
     aid-distributed: uint, 
     is-active: bool})

(define-map aid-plans
    uint 
    {plan-description: (string-ascii 256),
     requested-funds: uint,
     support-count: uint,
     is-executed: bool})

(define-map aid-beneficiaries
    uint
    {wallet-address: principal,
     crisis-id: uint,
     region-data: (string-ascii 64),
     impact-score: uint,
     is-validated: bool,
     validator-count: uint,
     secure-data: (string-ascii 1024),
     validation-data: (string-ascii 1024)})

(define-map beneficiary-validations
    {beneficiary-id: uint, validator-address: principal}
    bool)

(define-map approved-validators
    principal
    bool)

(define-map nft-data
    uint 
    (string-ascii 256))

(define-map token-holders
    uint
    principal)

;; NFT Implementation
(define-non-fungible-token guardian-token uint)

;; Read-Only Functions
(define-read-only (get-contributor-info (contributor-address principal))
    (default-to 
        {total-aid: u0, voting-power: u0, guardian-tokens: u0}
        (map-get? contributors contributor-address)))

(define-read-only (get-crisis-info (crisis-id uint))
    (map-get? crisis-registry crisis-id))

(define-read-only (get-beneficiary-info (beneficiary-id uint))
    (map-get? aid-beneficiaries beneficiary-id))

(define-read-only (check-validation-status (beneficiary-id uint))
    (let ((beneficiary (unwrap! (get-beneficiary-info beneficiary-id) (ok false))))
        (ok (get is-validated beneficiary))))

(define-read-only (get-total-aid-pool)
    (var-get total-aid-pool))

(define-read-only (get-token-owner (token-id uint))
    (ok (map-get? token-holders token-id)))

(define-read-only (get-token-data (token-id uint))
    (ok (map-get? nft-data token-id)))

(define-read-only (get-last-token-id)
    (ok (var-get last-guardian-id)))

;; Main Functions
(define-public (register-beneficiary 
    (crisis-id uint)
    (region-data (string-ascii 64))
    (impact-score uint)
    (secure-data (string-ascii 1024))
    (validation-data (string-ascii 1024)))
    (let ((beneficiary-id (+ (var-get last-beneficiary-index) u1))
          (crisis (unwrap! (get-crisis-info crisis-id) err-crisis-inactive)))
        (if (get is-active crisis)
            (begin
                (var-set last-beneficiary-index beneficiary-id)
                (map-set aid-beneficiaries beneficiary-id
                    {wallet-address: tx-sender,
                     crisis-id: crisis-id,
                     region-data: region-data,
                     impact-score: impact-score,
                     is-validated: false,
                     validator-count: u0,
                     secure-data: secure-data,
                     validation-data: validation-data})
                (ok beneficiary-id))
            err-crisis-inactive)))

;; Validator Management
(define-public (authorize-validator (validator-address principal))
    (if (is-eq tx-sender guardian-admin)
        (begin
            (map-set approved-validators validator-address true)
            (ok true))
        err-access-denied))

(define-public (validate-beneficiary (beneficiary-id uint))
    (let (
        (beneficiary (unwrap! (get-beneficiary-info beneficiary-id) err-access-denied))
        (is-validator (default-to false (map-get? approved-validators tx-sender)))
        (has-validated (default-to false (map-get? beneficiary-validations {beneficiary-id: beneficiary-id, validator-address: tx-sender})))
        )
        (if (and is-validator (not has-validated))
            (begin
                (map-set beneficiary-validations {beneficiary-id: beneficiary-id, validator-address: tx-sender} true)
                (map-set aid-beneficiaries beneficiary-id
                    (merge beneficiary 
                        {validator-count: (+ (get validator-count beneficiary) u1),
                         is-validated: (>= (+ (get validator-count beneficiary) u1) validation-requirement)}))
                (ok true))
            err-access-denied)))

;; Contribution Function
(define-public (contribute)
    (let ((contribution-amount (stx-get-balance tx-sender))
          (contributor-info (get-contributor-info tx-sender)))
        (if (>= contribution-amount min-contribution-amount)
            (begin
                (try! (stx-transfer? contribution-amount tx-sender (as-contract tx-sender)))
                (map-set contributors tx-sender
                    {total-aid: (+ (get total-aid contributor-info) contribution-amount),
                     voting-power: (+ (get voting-power contributor-info) contribution-amount),
                     guardian-tokens: (+ (get guardian-tokens contributor-info) u1)})
                (var-set total-aid-pool (+ (var-get total-aid-pool) contribution-amount))
                (let ((new-token-id (+ (var-get last-guardian-id) u1)))
                    (var-set last-guardian-id new-token-id)
                    (try! (nft-mint? guardian-token new-token-id tx-sender))
                    (map-set token-holders new-token-id tx-sender)
                    (map-set nft-data new-token-id nft-base-uri)
                    (ok true)))
            err-invalid-contribution)))

;; Additional Functions
(define-public (register-crisis (crisis-name (string-ascii 64)) (urgency-level uint) (aid-needed uint))
    (let ((crisis-id (+ (var-get current-crisis-index) u1)))
        (if (is-eq tx-sender guardian-admin)
            (begin
                (map-set crisis-registry crisis-id
                    {crisis-name: crisis-name,
                     urgency-level: urgency-level,
                     aid-needed: aid-needed,
                     aid-distributed: u0,
                     is-active: true})
                (var-set current-crisis-index crisis-id)
                (ok crisis-id))
            err-access-denied)))

(define-public (propose-aid-plan (crisis-id uint) (plan-description (string-ascii 256)) (requested-funds uint))
    (let ((crisis (unwrap! (get-crisis-info crisis-id) err-crisis-inactive)))
        (if (and 
                (get is-active crisis)
                (<= requested-funds (var-get total-aid-pool)))
            (begin
                (map-set aid-plans crisis-id
                    {plan-description: plan-description,
                     requested-funds: requested-funds,
                     support-count: u0,
                     is-executed: false})
                (ok true))
            err-insufficient-funds)))

(define-public (support-aid-plan (crisis-id uint))
    (let ((plan (unwrap! (map-get? aid-plans crisis-id) err-crisis-inactive))
          (contributor-info (get-contributor-info tx-sender)))
        (if (not (get is-executed plan))
            (begin
                (map-set aid-plans crisis-id
                    (merge plan {support-count: (+ (get support-count plan) (get voting-power contributor-info))}))
                (ok true))
            err-aid-plan-executed)))

(define-public (transfer-guardian-token (token-id uint) (sender-address principal) (recipient-address principal))
    (let ((current-owner (unwrap! (map-get? token-holders token-id) err-nft-nonexistent)))
        (if (and
                (is-eq tx-sender sender-address)
                (is-eq current-owner sender-address))
            (begin
                (map-set token-holders token-id recipient-address)
                (ok true))
            err-not-nft-owner)))

(define-public (update-crisis-urgency (crisis-id uint) (new-urgency-level uint))
    (let ((crisis (unwrap! (get-crisis-info crisis-id) err-crisis-inactive)))
        (if (is-eq tx-sender guardian-admin)
            (begin
                (map-set crisis-registry crisis-id
                    (merge crisis {urgency-level: new-urgency-level})) 
                (ok true))
            err-access-denied)))