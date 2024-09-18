# NFT Marketplace Smart Contract

This project implements a simple **Non-Fungible Token (NFT) Marketplace** on the **Stacks Blockchain** using the Clarity smart contract language. The contract allows users to mint, list, buy, and transfer NFTs.

## Features

- **Mint NFTs**: Users can mint unique NFTs with a specific ID.
- **List NFTs for Sale**: NFT owners can list their NFTs for sale at a set price.
- **Purchase NFTs**: Buyers can purchase listed NFTs by transferring STX tokens.
- **Transfer NFTs**: Owners can transfer NFTs to other users.

## Contract Overview

### Functions

1. **`(mint (nft-id uint))`**  
   Mints a new NFT with the given `nft-id`. The caller becomes the owner of the newly minted NFT.  
   **Parameters**:
   - `nft-id`: A unique identifier for the NFT (type: `uint`).

2. **`(list-nft (nft-id uint) (price uint))`**  
   Lists the NFT for sale with a specific price. Only the owner can list the NFT.  
   **Parameters**:
   - `nft-id`: The ID of the NFT to list (type: `uint`).
   - `price`: The sale price in micro-STX (type: `uint`).

3. **`(purchase-nft (nft-id uint))`**  
   Allows a buyer to purchase the listed NFT by transferring STX tokens to the seller.  
   **Parameters**:
   - `nft-id`: The ID of the NFT to purchase (type: `uint`).

4. **`(transfer-nft (nft-id uint) (recipient principal))`**  
   Transfers the ownership of an NFT to another user. Only the owner can transfer it.  
   **Parameters**:
   - `nft-id`: The ID of the NFT to transfer (type: `uint`).
   - `recipient`: The principal to whom the NFT will be transferred (type: `principal`).

### Error Codes

- **`u100`**: NFT with the given ID already exists.
- **`u101`**: Only the owner of the NFT can list it for sale.
- **`u102`**: Insufficient balance to purchase the NFT.
- **`u103`**: NFT is not listed for sale.
- **`u104`**: Only the owner can transfer the NFT.

## Prerequisites

To deploy and interact with this contract, you will need:

- **Clarity Developer Tools**: Set up the [Clarity Developer Environment](https://docs.stacks.co/write-smart-contracts/clarity-tutorial) to write, deploy, and test your Clarity contracts.
- **Stacks Wallet**: Use a Stacks wallet to interact with the blockchain and perform transactions.

## Author 

Blessing Chukwuma Unakalamba