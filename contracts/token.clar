;; Define the NFT
(define-non-fungible-token nft-id uint)

;; Define the listings map
(define-map listings
  {nft-id: uint}
  {seller: principal, price: uint})

;; Define the royalties map
(define-map royalties
  {nft-id: uint}
  {creator: principal, percentage: uint})

;; Define constants
(define-constant MIN_PRICE u1)
(define-constant MAX_PRICE u1000000000) ;; 1 billion microSTX
(define-constant MAX_ROYALTY_PERCENTAGE u20) ;; 20%
(define-constant ERR_NFT_NOT_LISTED (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_TRANSFER_FAILED (err u108))
(define-constant ERR_INVALID_ROYALTY (err u110))
(define-constant ERR_NOT_OWNER (err u111))
(define-constant ERR_LISTING_NOT_FOUND (err u112))
(define-constant ERR_NFT_ALREADY_EXISTS (err u113))
(define-constant ERR_NFT_DOES_NOT_EXIST (err u114))
(define-constant ERR_INVALID_TOKEN_ID (err u115))

;; Helper function to validate token-id
(define-private (is-valid-token-id (token-id uint))
  (< token-id (pow u2 u128)) ;; Assuming 128-bit max for uint
)

;; Mint a new NFT with royalty
(define-public (mint-with-royalty (token-id uint) (royalty-percentage uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (is-none (nft-get-owner? nft-id token-id)) ERR_NFT_ALREADY_EXISTS)
    (asserts! (<= royalty-percentage MAX_ROYALTY_PERCENTAGE) ERR_INVALID_ROYALTY)
    (try! (nft-mint? nft-id token-id tx-sender))
    (map-set royalties
      {nft-id: token-id}
      {creator: tx-sender, percentage: royalty-percentage})
    (ok true)
  )
)

;; List an NFT for sale
(define-public (list-nft (token-id uint) (price uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (let ((owner (nft-get-owner? nft-id token-id)))
      (asserts! (is-some owner) ERR_NFT_DOES_NOT_EXIST)
      (asserts! (is-eq (some tx-sender) owner) ERR_NOT_OWNER)
      (asserts! (and (>= price MIN_PRICE) (<= price MAX_PRICE)) (err u107))
      (ok (map-set listings
        {nft-id: token-id}
        {seller: tx-sender, price: price}))
    )
  )
)

;; Update the price of a listed NFT
(define-public (update-listing (token-id uint) (new-price uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (let ((listing (map-get? listings {nft-id: token-id})))
      (asserts! (is-some listing) ERR_NFT_NOT_LISTED)
      (let ((current-listing (unwrap-panic listing)))
        (asserts! (is-eq tx-sender (get seller current-listing)) ERR_NOT_OWNER)
        (asserts! (and (>= new-price MIN_PRICE) (<= new-price MAX_PRICE)) (err u107))
        (ok (map-set listings
          {nft-id: token-id}
          {seller: tx-sender, price: new-price}))
      )
    )
  )
)

;; Cancel a listing
(define-public (cancel-listing (token-id uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (let ((listing (map-get? listings {nft-id: token-id})))
      (asserts! (is-some listing) ERR_LISTING_NOT_FOUND)
      (let ((current-listing (unwrap-panic listing)))
        (asserts! (is-eq tx-sender (get seller current-listing)) ERR_NOT_OWNER)
        (ok (map-delete listings {nft-id: token-id}))
      )
    )
  )
)

;; Helper function to calculate royalty
(define-read-only (calculate-royalty (price uint) (percentage uint))
  (/ (* price percentage) u100)
)

;; Purchase an NFT from the marketplace
(define-public (purchase-nft (token-id uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (let ((listing (map-get? listings {nft-id: token-id})))
      (asserts! (is-some listing) ERR_NFT_NOT_LISTED)
      (let (
        (current-listing (unwrap-panic listing))
        (royalty-info (default-to {creator: tx-sender, percentage: u0} (map-get? royalties {nft-id: token-id})))
        (buyer tx-sender)
      )
        (let (
          (seller (get seller current-listing))
          (price (get price current-listing))
          (royalty-amount (calculate-royalty price (get percentage royalty-info)))
          (seller-amount (- price royalty-amount))
        )
          (begin
            (asserts! (is-some (nft-get-owner? nft-id token-id)) ERR_NFT_DOES_NOT_EXIST)
            (asserts! (>= (stx-get-balance buyer) price) ERR_INSUFFICIENT_FUNDS)
            ;; Transfer royalty to creator
            (if (> royalty-amount u0)
              (try! (stx-transfer? royalty-amount buyer (get creator royalty-info)))
              true
            )
            ;; Transfer remaining amount to seller
            (try! (stx-transfer? seller-amount buyer seller))
            (match (nft-transfer? nft-id token-id seller buyer)
              success (begin
                (map-delete listings {nft-id: token-id})
                (ok true))
              error (begin
                (try! (stx-transfer? price seller buyer))
                ERR_TRANSFER_FAILED))
          )
        )
      )
    )
  )
)

;; Transfer an NFT to another user
(define-public (transfer-nft (token-id uint) (recipient principal))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (let ((owner (nft-get-owner? nft-id token-id)))
      (asserts! (is-some owner) ERR_NFT_DOES_NOT_EXIST)
      (asserts! (is-eq (some tx-sender) owner) ERR_NOT_OWNER)
      (nft-transfer? nft-id token-id tx-sender recipient)
    )
  )
)

;; Get royalty information for an NFT
(define-read-only (get-royalty-info (token-id uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (ok (default-to 
      {creator: tx-sender, percentage: u0}
      (map-get? royalties {nft-id: token-id})))
  )
)