- the structure of the Auction at the moment: 
  - Only single auction possible
  - Bidders use a payable function to pay for the bid
    - The payment is added to the contract balance
    - problem: each time user wants to outbid they would have to pay in ether over and over while each previous bid money is locked in the contract
    - solution: return the previous bid amount to the user everytime they are outbidded. Probably would cost a bit of gas. But its a nice simple solution


