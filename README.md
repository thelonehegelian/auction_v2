- the structure of the Auction at the moment: 
  - Only single auction possible
  - Bidders uses a payable function to pay for the bid
    - The payment is added to the contract balance
    - problem: each time user wants to outbid they would have to pay in ether over and over while each previous bid money is locked in the contract
    - solution: return the previous bid amount to the user everytime they are outbidded. Probably would cost a bit of gas. But its a nice simple solution


# Auction Contract

## Description and Logic

- Allows a user to create an auction with a list of items
- Allows other users to bid on items in the auction
- There is a time limit for the auction, 
  - [ ] which is fixed for now but perhaps should be set at `createBid`
- Once the auction has ended no more bids are taken
- `sold` bool is set to true after the auction has finished and no one can change that
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
- For `revert` the same OPCODE is used as with `require` since the update (can't remember now, think it was last year)

### Restrictions
- To set access control I am using OpenZeppelin's `Ownable` contract. It probably costs more gas (?)
  - Simple modifier would work too in such a simple contract but generally my rule is to use an audited contract where possible
  - Ownable contracts could have their ownership transferred so that is handy in this particular case

- Contract deployer is set as the `owner` of the contract
- Only owner of the contract can create a new auction 
- Only non-owners can call the `placeBid` function


# Tests
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
- Would be nice to handle ERC20 for bids
- Liked to have used an Oracle to set prices in USD or even a sort of NFT barter system
- Would be nice to use NFTs  for each item 
- For better user experience gas cost can probably reduced more, using bytes instead of strings etc.
- Sell certain quantity of items, with each piece sold the price of the item increases by a percentage
- Allow bidders to set a maximum bid as well i.e. how high they are willing to go. Would save them gas cost of trying to constantly outbid
- A basic frontend would have been nice and simple to implement for this
- Maybe some prevention against sniping bots(?)