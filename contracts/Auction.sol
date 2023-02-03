// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ownable openzeppelin
// import "@openzeppelin/contracts/access/Ownable.sol";

/* 
@todo install openzeppelin
@todo create a factory contract
@todo create frontend if time permits


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

    // !is this even gonna work?
    function createAuction(uint auctionId, Item memory item) public onlyOwner {
        Auctions storage _auctions = auctions[auctionId++];
        _auctions.auctionId = auctionId;
        _auctions.item = item;
        _auctions.highestBid = 0; // not necessary, solidity does this by default
        _auctions.highestBidder = address(0); // not necessary, solidity does this by default
        _auctions.auctionEndTime = block.timestamp + 1 days;

        emit AuctionCreated(auctionId, item);
    }

    function placeBids(uint auctionId) public payable {
        require(
            msg.value > auctions[auctionId].highestBid,
            "Your bid is lower than the highest bid." // @todo use custom error to save gas
        );

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
    }
}
