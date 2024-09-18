(define-non-fungible-token nft-id uint)

(define-map listings
  ((nft-id uint)) ;; Key: NFT ID
  ((seller principal) (price uint))) ;; Value: Seller and Price

(define-public (mint (nft-id uint))
  ;; Mint a new NFT to the sender
  (begin
    (asserts! (is-none (nft-get-owner? nft-id)) (err u100)) ;; Ensure NFT doesn't already exist
    (nft-mint? nft-id tx-sender)
  )
)

(define-public (list-nft (nft-id uint) (price uint))
  ;; List an NFT for sale
  (let ((owner (nft-get-owner? nft-id)))
    (begin
      (asserts! (is-eq owner (some tx-sender)) (err u101)) ;; Ensure the sender is the owner
      (map-set listings
        ((nft-id nft-id))
        ((seller tx-sender) (price price)))
      (ok (some price))
    )
  )
)

(define-public (purchase-nft (nft-id uint))
  ;; Purchase an NFT from the marketplace
  (let
    (
      (listing (map-get listings ((nft-id nft-id))))
      (buyer tx-sender)
    )
    (match listing
      listing-data
      (let
        (
          (seller (get seller listing-data))
          (price (get price listing-data))
        )
        (begin
          (asserts! (>= (stx-get-balance buyer) price) (err u102)) ;; Ensure buyer has enough STX
          (stx-transfer? price buyer seller) ;; Transfer STX from buyer to seller
          (nft-transfer? nft-id seller buyer) ;; Transfer NFT from seller to buyer
          (map-delete listings ((nft-id nft-id))) ;; Remove the NFT from the listing
          (ok buyer)
        )
      )
      (err u103) ;; NFT is not listed for sale
    )
  )
)

(define-public (transfer-nft (nft-id uint) (recipient principal))
  ;; Transfer an NFT to another user
  (let ((owner (nft-get-owner? nft-id)))
    (begin
      (asserts! (is-eq owner (some tx-sender)) (err u104)) ;; Ensure the sender is the owner
      (nft-transfer? nft-id tx-sender recipient) ;; Transfer NFT
      (ok recipient)
    )
  )
)
