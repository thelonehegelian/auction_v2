// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ownable openzeppelin
// import "@openzeppelin/contracts/access/Ownable.sol";

/* 
@todo install openzeppelin
@todo use openzeppelin's ownable
@todo create frontend if time permits
@note who receives the bid amount? the auctioneer or the contract itself?

*/

contract Auction {
    // state variables
    address public owner;

    struct Auctions {
        uint auctionId;
        Item item;
        uint256 highestBid;
        address highestBidder;
        uint256 auctionEndTime;
    }
    struct Item {
        string itemName;
        uint256 itemPrice; // starting price
    }

    mapping(uint => Auctions) public auctions;
    mapping(address => uint) public bidders;

    constructor() {
        owner = msg.sender;
    }

    /***********
     *  EVENTS *
     ***********/

    event AuctionCreated(uint auctionId, Item item);
    event BidPlaced(uint auctionId, uint256 highestBid, address highestBidder);
    event AuctionEnded(
        uint auctionId,
        uint256 highestBid,
        address highestBidder
    );

    /*********
     *  MAIN *
     *********/

    // !is this even gonna work? probably not yet
    // @todo auctioneer must put ERC20 token
    function createAuction(uint auctionId, Item memory item) public onlyOwner {
        Auctions storage _auctions = auctions[auctionId++];
        _auctions.auctionId = auctionId;
        _auctions.item = item;
        // @note could be a mapping?
        _auctions.highestBid = item.itemPrice; // starting price, this way we won't have to check if the bid is higher than the starting price
        _auctions.highestBidder = address(0); // not necessary, solidity does this by default
        _auctions.auctionEndTime = block.timestamp + 1 days;

        emit AuctionCreated(auctionId, item);
    }

    // * this function adds balance to the contract
    function placeBid(uint auctionId) public payable {
        // require that auctionEndTime is not yet reached
        require(
            auctions[auctionId].auctionEndTime > block.timestamp,
            "Auction has ended."
        );

        require(
            msg.value > auctions[auctionId].highestBid,
            "Your bid is lower than the highest bid." // @todo use custom error to save gas
        );
        require(
            block.timestamp < auctions[auctionId].auctionEndTime,
            "Auction has ended." // @todo use custom error to save gas
        );
        require(msg.sender != owner, "Owner cannott bid on their own auction."); // @todo use custom error to save gas

        auctions[auctionId].highestBid = msg.value;
        auctions[auctionId].highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.value, msg.sender);
    }

    // onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function."); // @todo use custom error to save gas
        _;
    }

    /************
     *  HELPERS *
     ************/

    function findHighestBidder() private {
        // is this function a requirement?
        // has the auction ended?
        // is the highest bid higher than the item price?
        // is the highest bid higher than the highest bid?
        // return money to all the bidders except the highest bidder
    }
}
