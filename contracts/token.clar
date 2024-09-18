;; Define the NFT
(define-non-fungible-token nft-id uint)

;; Define the listings map
(define-map listings
  {nft-id: uint}
  {seller: principal, price: uint})

;; Define constants
(define-constant MIN_PRICE u1)
(define-constant MAX_PRICE u1000000000) ;; 1 billion microSTX, adjust as needed
(define-constant ERR_NFT_NOT_LISTED (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_TRANSFER_FAILED (err u108))

;; Mint a new NFT
(define-public (mint (token-id uint))
  (begin
    (asserts! (is-none (nft-get-owner? nft-id token-id)) (err u100))
    (nft-mint? nft-id token-id tx-sender)
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

;; Purchase an NFT from the marketplace
(define-public (purchase-nft (token-id uint))
  (let (
    (listing (unwrap! (map-get? listings {nft-id: token-id}) ERR_NFT_NOT_LISTED))
    (buyer tx-sender)
  )
    (let (
      (seller (get seller listing))
      (price (get price listing))
    )
      (begin
        (asserts! (is-some (nft-get-owner? nft-id token-id)) (err u109))
        (asserts! (>= (stx-get-balance buyer) price) ERR_INSUFFICIENT_FUNDS)
        (try! (stx-transfer? price buyer seller))
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