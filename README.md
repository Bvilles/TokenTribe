# NFT Marketplace Smart Contract with Auction Mechanism

This project implements an advanced **Non-Fungible Token (NFT) Marketplace** on the **Stacks Blockchain** using the Clarity smart contract language. The contract allows users to mint, list, buy, transfer NFTs, and participate in auctions.

## Features

- **Mint NFTs**: Users can mint unique NFTs with a specific ID and set royalties.
- **List NFTs for Sale**: NFT owners can list their NFTs for sale at a set price.
- **Purchase NFTs**: Buyers can purchase listed NFTs by transferring STX tokens.
- **Transfer NFTs**: Owners can transfer NFTs to other users.
- **Auction NFTs**: NFT owners can start auctions for their tokens.
- **Bid on NFTs**: Users can place bids on auctioned NFTs.
- **End Auctions**: Auctions can be ended, transferring the NFT to the highest bidder.

## Contract Overview

### Core Functions

1. **`(mint-with-royalty (token-id uint) (royalty-percentage uint))`**  
   Mints a new NFT with the given `token-id` and sets a royalty percentage. The caller becomes the owner of the newly minted NFT.

2. **`(list-nft (token-id uint) (price uint))`**  
   Lists the NFT for sale with a specific price. Only the owner can list the NFT.

3. **`(purchase-nft (token-id uint))`**  
   Allows a buyer to purchase the listed NFT by transferring STX tokens to the seller and royalties to the creator.

4. **`(transfer-nft (token-id uint) (recipient principal))`**  
   Transfers the ownership of an NFT to another user. Only the owner can transfer it.

### Auction Functions

5. **`(start-auction (token-id uint) (min-bid uint) (duration uint))`**  
   Starts an auction for the specified NFT with a minimum bid and duration.

6. **`(place-bid (token-id uint) (bid-amount uint))`**  
   Places a bid on an auctioned NFT. The bid must be higher than the current highest bid or the minimum bid.

7. **`(end-auction (token-id uint))`**  
   Ends the auction for the specified NFT, transferring it to the highest bidder and distributing funds.

### Read-Only Functions

8. **`(get-royalty-info (token-id uint))`**  
   Retrieves the royalty information for a specific NFT.

9. **`(get-auction-info (token-id uint))`**  
   Retrieves the current auction information for an NFT.

10. **`(get-highest-bid (token-id uint))`**  
    Retrieves the current highest bid for an auctioned NFT.

### Error Codes

- **`u100`**: NFT with the given ID already exists.
- **`u101`**: Only the owner of the NFT can perform this action.
- **`u102`**: Insufficient balance to complete the transaction.
- **`u103`**: NFT is not listed for sale.
- **`u104`**: NFT does not exist.
- **`u105`**: Invalid token ID.
- **`u106`**: Invalid royalty percentage.
- **`u107`**: Invalid price (too low or too high).
- **`u108`**: Transfer failed.
- **`u109`**: Auction not found.
- **`u110`**: Auction has ended.
- **`u111`**: Auction has not ended yet.
- **`u112`**: Bid too low.
- **`u113`**: Invalid auction duration.
- **`u114`**: No bids placed on the auction.

## Prerequisites

To deploy and interact with this contract, you will need:

- **Clarity Developer Tools**: Set up the [Clarity Developer Environment](https://docs.stacks.co/write-smart-contracts/clarity-tutorial) to write, deploy, and test your Clarity contracts.
- **Stacks Wallet**: Use a Stacks wallet to interact with the blockchain and perform transactions.

## Usage

1. Deploy the contract to the Stacks blockchain.
2. Use the provided functions to mint NFTs, list them for sale or auction, place bids, and transfer ownership.
3. Ensure you have sufficient STX balance when purchasing NFTs or placing bids.
4. Be aware of the royalty system when purchasing NFTs, as a portion of the sale price will go to the original creator.

## Security Considerations

- The contract includes checks for valid token IDs, sufficient balances, and proper ownership.
- Auction durations and bid amounts are constrained to prevent potential exploits.
- Always review and test thoroughly before deploying to mainnet.

## Author 

Blessing Chukwuma Unakalamba

## License

This project is licensed under the MIT License.