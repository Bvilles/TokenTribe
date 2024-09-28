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

;; Define the auctions map
(define-map auctions
  {nft-id: uint}
  {seller: principal, min-bid: uint, end-block: uint})

;; Define the bids map
(define-map bids
  {nft-id: uint}
  {bidder: principal, amount: uint})

;; Define constants
(define-constant MIN_PRICE u1)
(define-constant MAX_PRICE u1000000000) ;; 1 billion microSTX
(define-constant MAX_ROYALTY_PERCENTAGE u20) ;; 20%
(define-constant MIN_AUCTION_DURATION u100) ;; Minimum auction duration in blocks
(define-constant MAX_AUCTION_DURATION u10000) ;; Maximum auction duration in blocks
(define-constant ERR_NFT_NOT_LISTED (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_TRANSFER_FAILED (err u108))
(define-constant ERR_INVALID_ROYALTY (err u110))
(define-constant ERR_NOT_OWNER (err u111))
(define-constant ERR_LISTING_NOT_FOUND (err u112))
(define-constant ERR_NFT_ALREADY_EXISTS (err u113))
(define-constant ERR_NFT_DOES_NOT_EXIST (err u114))
(define-constant ERR_INVALID_TOKEN_ID (err u115))
(define-constant ERR_AUCTION_NOT_FOUND (err u116))
(define-constant ERR_AUCTION_ENDED (err u117))
(define-constant ERR_AUCTION_NOT_ENDED (err u118))
(define-constant ERR_BID_TOO_LOW (err u119))
(define-constant ERR_INVALID_AUCTION_DURATION (err u120))

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

;; Start an auction for an NFT
(define-public (start-auction (token-id uint) (min-bid uint) (duration uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (asserts! (is-eq (nft-get-owner? nft-id token-id) (some tx-sender)) ERR_NOT_OWNER)
    (asserts! (and (>= duration MIN_AUCTION_DURATION) (<= duration MAX_AUCTION_DURATION)) ERR_INVALID_AUCTION_DURATION)
    (ok (map-set auctions
      {nft-id: token-id}
      {seller: tx-sender, min-bid: min-bid, end-block: (+ block-height duration)}))
  )
)

;; Place a bid on an auctioned NFT
(define-public (place-bid (token-id uint) (bid-amount uint))
  (let ((auction (unwrap! (map-get? auctions {nft-id: token-id}) ERR_AUCTION_NOT_FOUND)))
    (begin
      (asserts! (< block-height (get end-block auction)) ERR_AUCTION_ENDED)
      (asserts! (>= bid-amount (get min-bid auction)) ERR_BID_TOO_LOW)
      (let ((current-bid (map-get? bids {nft-id: token-id})))
        (match current-bid
          prev-bid (asserts! (> bid-amount (get amount prev-bid)) ERR_BID_TOO_LOW)
          true
        )
      )
      (asserts! (>= (stx-get-balance tx-sender) bid-amount) ERR_INSUFFICIENT_FUNDS)
      (map-set bids {nft-id: token-id} {bidder: tx-sender, amount: bid-amount})
      (ok true)
    )
  )
)

;; End an auction and transfer the NFT to the highest bidder
(define-public (end-auction (token-id uint))
  (let (
    (auction (unwrap! (map-get? auctions {nft-id: token-id}) ERR_AUCTION_NOT_FOUND))
    (highest-bid (unwrap! (map-get? bids {nft-id: token-id}) (err u121))) ;; No bids placed
  )
    (begin
      (asserts! (>= block-height (get end-block auction)) ERR_AUCTION_NOT_ENDED)
      (let (
        (seller (get seller auction))
        (winner (get bidder highest-bid))
        (winning-bid (get amount highest-bid))
        (royalty-info (default-to {creator: tx-sender, percentage: u0} (map-get? royalties {nft-id: token-id})))
        (royalty-amount (calculate-royalty winning-bid (get percentage royalty-info)))
        (seller-amount (- winning-bid royalty-amount))
      )
        (begin
          ;; Transfer royalty to creator
          (if (> royalty-amount u0)
            (try! (stx-transfer? royalty-amount winner (get creator royalty-info)))
            true
          )
          ;; Transfer remaining amount to seller
          (try! (stx-transfer? seller-amount winner seller))
          ;; Transfer NFT to winner
          (try! (nft-transfer? nft-id token-id seller winner))
          ;; Clean up auction and bid data
          (map-delete auctions {nft-id: token-id})
          (map-delete bids {nft-id: token-id})
          (ok true)
        )
      )
    )
  )
)

;; Get current auction information for an NFT
(define-read-only (get-auction-info (token-id uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (ok (map-get? auctions {nft-id: token-id}))
  )
)

;; Get current highest bid for an auctioned NFT
(define-read-only (get-highest-bid (token-id uint))
  (begin
    (asserts! (is-valid-token-id token-id) ERR_INVALID_TOKEN_ID)
    (ok (map-get? bids {nft-id: token-id}))
  )
)