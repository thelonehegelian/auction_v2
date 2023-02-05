# Auction Contract

# Note to the assessor 
- the code is over-commented, but that is just for the assignment

## Description and Logic

- Allows a user to create an auction with a list of items
- Allows other users to bid on items in the auction
- There is a time limit for the auction, 
  - [ ] which is fixed for now but perhaps should be set at `createBid`
- Once the auction has ended no more bids are taken
- 

### Objects
- AuctionDetails
  - Why `auctionId` and `auctionName`? I had planned to add a Factory contract to make it more interesting
- Item

### Functions
- `createAuction` -> Allows the owner to create an auction with a list of items
- `placeBid` -> Allows users to place bids on the items
  - each higher bid removes the highest bidder from the Item struct and returns their money
  - [ ] other possible solutions to this?
- `transferToPrevBidder` -> A helper function to transfer to losing bidder
- `findHighestBidder` -> A helper function to find the highest bidder for each item
### Events
- Events can be useful for Frontend, and an Auction contract is likely to be a Frontend application 
- `AuctionCreated`
- `BidPlaced`
- `AuctionEnded` 
### Errors
- Custom errors can cost quite a bit of gas 
- For `revert` the same OPCODE is used as with `require` since the update (think it was last year)

### Restrictions
- To set access control I am using OpenZeppelin's `Ownable` contract. It probably costs more gas (?)
  - Simple modifier would work too in such a simple contract but generally my rule is to use an audited contract where possible
  - Ownable contracts could have their ownership transferred so that is handy in this particular case

- Contract deployer is set as the `owner` of the contract
- Only owner of the contract can create a new auction 
- Only non-owners can call the `placeBid` function
- OnlyOwner can call the `findHighestBidder` function (assuming that this would be called for the frontend only)
- 


# Tests
- There are test helper functions in the contract. I usually don't do it like this but in this case I needed to be quick to make sure everything worked as intended
- Mostly self explanatory (in order):
1. `contract creator should be the owner`
2. `allow owner of the contract to create auctions`
   1. [ ] both above should be one test
3. `creates an auction`
4. `does not allow owner of the auction to bid`
5. `bidding less than highest bid is not allowed`
6. `allow bid greater than highest bid`
7. `not allow bid after auction end time`

# Things would have like to try
- I would have liked to add a Factory contract. Usually such contracts come with Factory contracts to allow various users to create different contracts of the same type. The basic Factory contract is there in the contracts folder but I did not implement
- ERC20 support 
- Liked to have used an Oracle to set prices in USD or even a sort of NFT barter system
- Would be nice to use NFT representation for each item 
- For better user experience gas cost can probably reduced more, using bytes instead of strings etc.
- Sell certain quantity of items, with each piece sold the price of the item increases by a percentage
- Allow bidders to set a maximum bid as well i.e. how high they are willing to go. Would save them gas cost of trying to constantly outbid
- Maybe some prevention against sniping bots(?)
- Allow for a reserve price to be set at the start of the auction
- If starting price is not moved within a specific period of time the bid is lowered by a certain amount
- Dutch auction type


