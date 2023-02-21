# Auction Contract
## Description and Logic
- A basic auction contract that allows a user to create an auction with a list of items
- Allows other users to bid on items in the auction
- There is a time limit for the auction, which is fixed for now
- Once the auction has ended no more bids are taken
- `findHighestBidder` is used to find the highest bid nothing else is done at the end of the auction

### Restrictions
- Contract deployer is set as the `owner` of the contract
- Only owner of the contract can create a new auction 
- Only non-owners can call the `placeBid` function
- OnlyOwner can call the `findHighestBidder` function (assuming that this would be called for the frontend only), can also be made to use to settle auction
- `findHighestBidder` cannot be called unless the auction time is up