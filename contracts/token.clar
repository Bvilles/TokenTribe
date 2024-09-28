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

;; Mint a new NFT with royalty
(define-public (mint-with-royalty (token-id uint) (royalty-percentage uint))
  (begin
    (asserts! (is-none (nft-get-owner? nft-id token-id)) (err u100))
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
  (let ((owner (nft-get-owner? nft-id token-id)))
    (begin
      (asserts! (is-some owner) (err u105))
      (asserts! (is-eq (some tx-sender) owner) (err u101))
      (asserts! (and (>= price MIN_PRICE) (<= price MAX_PRICE)) (err u107))
      (ok (map-set listings
        {nft-id: token-id}
        {seller: tx-sender, price: price}))
    )
  )
)

;; Update the price of a listed NFT
(define-public (update-listing (token-id uint) (new-price uint))
  (let (
    (listing (unwrap! (map-get? listings {nft-id: token-id}) ERR_NFT_NOT_LISTED))
    (seller (get seller listing))
  )
    (begin
      (asserts! (is-eq tx-sender seller) ERR_NOT_OWNER)
      (asserts! (and (>= new-price MIN_PRICE) (<= new-price MAX_PRICE)) (err u107))
      (ok (map-set listings
        {nft-id: token-id}
        {seller: seller, price: new-price}))
    )
  )
)

;; Cancel a listing
(define-public (cancel-listing (token-id uint))
  (let (
    (listing (unwrap! (map-get? listings {nft-id: token-id}) ERR_LISTING_NOT_FOUND))
    (seller (get seller listing))
  )
    (begin
      (asserts! (is-eq tx-sender seller) ERR_NOT_OWNER)
      (ok (map-delete listings {nft-id: token-id}))
    )
  )
)

;; Helper function to calculate royalty
(define-read-only (calculate-royalty (price uint) (percentage uint))
  (/ (* price percentage) u100)
)

;; Purchase an NFT from the marketplace
(define-public (purchase-nft (token-id uint))
  (let (
    (listing (unwrap! (map-get? listings {nft-id: token-id}) ERR_NFT_NOT_LISTED))
    (royalty-info (default-to {creator: tx-sender, percentage: u0} (map-get? royalties {nft-id: token-id})))
    (buyer tx-sender)
  )
    (let (
      (seller (get seller listing))
      (price (get price listing))
      (royalty-amount (calculate-royalty price (get percentage royalty-info)))
      (seller-amount (- price royalty-amount))
    )
      (begin
        (asserts! (is-some (nft-get-owner? nft-id token-id)) (err u109))
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

;; Transfer an NFT to another user
(define-public (transfer-nft (token-id uint) (recipient principal))
  (let ((owner (nft-get-owner? nft-id token-id)))
    (begin
      (asserts! (is-some owner) (err u106))
      (asserts! (is-eq (some tx-sender) owner) (err u104))
      (nft-transfer? nft-id token-id tx-sender recipient)
    )
  )
)

;; Get royalty information for an NFT
(define-read-only (get-royalty-info (token-id uint))
  (default-to {creator: tx-sender, percentage: u0}
    (map-get? royalties {nft-id: token-id}))
)