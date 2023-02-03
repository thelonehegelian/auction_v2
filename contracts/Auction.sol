// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
// ownable openzeppelin
// import "@openzeppelin/contracts/access/Ownable.sol";

/* 
@todo install openzeppelin
@todo use openzeppelin's ownable
@todo create frontend if time permits
@todo update the contract: see requirements
@todo run slither
*/

contract Auction {
    // state variables
    address public owner;

    struct Auctions {
        uint auctionId;
        string auctionName; // @todo make things quirky, AuctionName: Southeby's Auction of the Century
        // AuctionName: Worst Mistake of Your Life
        Item item;
        uint256 highestBid;
        address payable highestBidder; // @note is payable necessary? yes it is because we need to transfer money to the previous highest bidder
        uint256 auctionEndTime;
    }
    struct Item {
        string itemName;
        uint256 itemPrice; // starting price
        // address highestBidder; @todo uncomment this and update the code
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
        // _auctions.highestBidder = address (0); // not necessary, solidity does this by default
        _auctions.auctionEndTime = block.timestamp + 1 days;

        emit AuctionCreated(auctionId, item);
    }

    // * this function adds balance to the contract
    function placeBid(uint auctionId) public payable {
        // if the auction time has ended then find the highest bidder and transfer the item to the highest bidder
        if (auctions[auctionId].auctionEndTime > block.timestamp) {
            findHighestBidder(auctionId);
        }

        require(
            auctions[auctionId].auctionEndTime > block.timestamp,
            "Auction has ended." // @todo use custom error to save gas
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

        // if the above conditions are met then we want to transger the previous highest bidder their money
        address prevHighestBidder = auctions[auctionId].highestBidder;
        uint256 prevHighestBid = auctions[auctionId].highestBid;

        auctions[auctionId].highestBid = msg.value;
        auctions[auctionId].highestBidder = payable(msg.sender);
        transferToPrevBidder(payable(prevHighestBidder), prevHighestBid);
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

    function findHighestBidder(uint _auctionId) private {
        address auctionWinner = auctions[_auctionId].highestBidder;
        uint256 highestBid = auctions[_auctionId].highestBid;
        // @todo find the highest bidder for each item
        emit AuctionEnded(_auctionId, highestBid, auctionWinner);
    }

    function transferToPrevBidder(
        address payable _prevBidder,
        uint prevHighestBid
    ) private {
        _prevBidder.transfer(prevHighestBid);
    }
}
