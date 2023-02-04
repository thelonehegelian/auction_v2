// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    /*********************
     *  STATE VARIABLES  *
     *********************/
    struct Auctions {
        uint auctionId;
        string auctionName;
        Item[] items;
        uint256 auctionEndTime;
    }

    struct Item {
        uint itemId;
        string itemName;
        uint256 startingPrice; // starting price @todo change name to startingPrice
        uint highestBid;
        address highestBidder;
    }

    mapping(uint => Auctions) public auctions;

    uint auctionId = 0;

    /**********
     * EVENTS *
     **********/

    // @todo should be indexed
    event AuctionCreated(uint auctionId, Item item);
    event BidPlaced(uint auctionId, uint256 highestBid, address highestBidder);
    event AuctionEnded(uint auctionId, string auctionName);

    /*********
     * MAIN *
     *********/

    function createAuction(
        Item[] memory items,
        string memory auctionName
    ) public onlyOwner {
        Auctions memory newAuction = auctions[auctionId];
        // @note not allowed to do this newAuction.items = items, because not allowed to map memory to storage directly
        _createItemList(items);
        newAuction.auctionId = auctionId;
        newAuction.auctionName = auctionName;
        newAuction.auctionEndTime = block.timestamp + 1 days;
    }

    // * this function adds balance to the contract
    function placeBid(uint _auctionId, uint _itemId) public payable {
        // if the auction time has ended then find the highest bidder and emit the event AuctionEnded
        if (auctions[_auctionId].auctionEndTime > block.timestamp) {
            payable(msg.sender).transfer(msg.value);
            emit AuctionEnded(_auctionId, auctions[_auctionId].auctionName);
            return;
        }

        require(
            msg.value >= auctions[_auctionId].items[_itemId].startingPrice,
            "Bid amount is less than the starting price."
        ); // @todo use custom error to save gas

        require(
            msg.value > auctions[_auctionId].items[_itemId].highestBid,
            "Bid amount is less than the highest bid."
        ); // @todo use custom error to save gas

        require(
            msg.sender != owner(),
            "Owner cannott bid on their own auction."
        ); // @todo use custom error to save gas

        require(
            block.timestamp < auctions[_auctionId].auctionEndTime,
            "Auction has ended."
        ); // @todo use custom error to save gas

        // if the above conditions are met then we want to transfer the previous highest bidder their money
        address prevHighestBidder = auctions[_auctionId]
            .items[_itemId]
            .highestBidder;
        uint256 prevHighestBid = auctions[auctionId].items[_itemId].highestBid;

        // we update the highest bid and highest bidder
        auctions[auctionId].items[_itemId].highestBid = msg.value;
        auctions[auctionId].items[_itemId].highestBidder = payable(msg.sender);
        // we refund the previous highest bidder their money, as they have been outbid
        _transferToPrevBidder(payable(prevHighestBidder), prevHighestBid);
        emit BidPlaced(auctionId, msg.value, msg.sender);
    }

    // Finds the highest bidder for each item in the auction and returns an array of addresses
    function findHighestBidders(
        uint _auctionId
    ) public view onlyOwner returns (uint[] memory, address[] memory) {
        require(
            auctions[_auctionId].auctionEndTime < block.timestamp,
            "Auction has not ended yet."
        );

        Item[] memory itemList = auctions[_auctionId].items;
        address[] memory highestBidders = new address[](itemList.length);
        uint[] memory itemIds = new uint[](itemList.length);

        for (uint i = 0; i < itemList.length; i++) {
            highestBidders[i] = itemList[i].highestBidder;
            itemIds[i] = itemList[i].itemId;
        }
        return (itemIds, highestBidders);
    }

    /************
     * HELPERS *
     ************/

    function _transferToPrevBidder(
        address payable _prevBidder,
        uint prevHighestBid
    ) private {
        _prevBidder.transfer(prevHighestBid);
    }

    function _createItemList(Item[] memory _itemsList) private {
        for (uint i = 0; i < _itemsList.length; i++) {
            auctions[auctionId].items.push(_itemsList[i]);
        }
    }

    /****************
     * TEST HELPERS *
     ****************/

    function getAuction(uint _auctionId) public view returns (Auctions memory) {
        return auctions[_auctionId];
    }

    function getAuctionItems(
        uint _auctionId
    ) public view returns (Item[] memory) {
        return auctions[_auctionId].items;
    }
}
