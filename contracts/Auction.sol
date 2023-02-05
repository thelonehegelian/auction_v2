// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    /*********************
     *  STATE VARIABLES  *
     *********************/
    struct Auctions {
        uint auctionId;
        string auctionName;
        Item[] items;
        uint auctionEndTime;
        bool isEnded;
    }

    struct Item {
        uint itemId;
        string itemName;
        uint256 startingPrice;
        uint highestBid;
        address highestBidder;
    }

    mapping(uint => Auctions) public auctions;

    uint auctionId = 0;

    /**********
     * ERRORS *
     **********/
    error BidAmountLessThanStartingPrice();
    error BidAmountLessThanHighestBid();
    error OwnerCannotBidOnOwnAuction();
    error AuctionHasNotEnded();
    error AuctionHasEnded();

    /**********
     * EVENTS *
     **********/

    // @todo should be indexed for better filtering in the frontend
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
        Auctions storage newAuction = auctions[auctionId];
        // @note can't do this: newAuction.items = items, because not allowed to map memory to storage directly
        _createItemList(items);
        newAuction.auctionId = auctionId;
        newAuction.auctionName = auctionName;
        /**  
         block.timestamp is not always suited, as it can be manipulated by miners but only a few seconds, in this case it should be okay
         https://stackoverflow.com/questions/71000103/solidity-block-timestamp-vulnerability
         https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/timestamp-dependence/
         this might be a better solution but never tried it:
         https://docs.chain.link/chainlink-automation/introduction/#time-based-trigger
         */
        newAuction.auctionEndTime = block.timestamp + 1 days;
        newAuction.isEnded = false;
        auctionId++;
    }

    // *this function adds balance to the contract
    function placeBid(
        uint _auctionId,
        uint _itemId
    )
        public
        payable
        nonOwner
        // @todo can I combine these two modifiers into one?
        bidMustBeValid(_auctionId, _itemId)
    {
        // // if the auction time has ended then find the highest bidder and emit the event AuctionEnded
        if (block.timestamp >= auctions[_auctionId].auctionEndTime) {
            // @note a private _endAuction function can be used take care of the settlement here
            emit AuctionEnded(_auctionId, auctions[_auctionId].auctionName);
            revert AuctionHasEnded();
        }

        // we transfer the previous highest bid to the previous highest bidder
        address prevHighestBidder = auctions[_auctionId]
            .items[_itemId]
            .highestBidder;
        uint prevHighestBid = auctions[_auctionId].items[_itemId].highestBid;
        _transferToPrevBidder(payable(prevHighestBidder), prevHighestBid);
        // update the highest bid and highest bidder
        auctions[_auctionId].items[_itemId].highestBid = msg.value;
        auctions[_auctionId].items[_itemId].highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.value, msg.sender);
    }

    // Finds the highest bidder for each item in the auction and returns an array of addresses
    function findHighestBidders(
        uint _auctionId
    ) public view onlyOwner returns (uint[] memory, address[] memory) {
        if (block.timestamp <= auctions[_auctionId].auctionEndTime) {
            revert AuctionHasNotEnded();
        }

        Item[] memory itemList = auctions[_auctionId].items;
        address[] memory highestBidders = new address[](itemList.length);
        uint[] memory itemIds = new uint[](itemList.length);

        for (uint i = 0; i < itemList.length; i++) {
            highestBidders[i] = itemList[i].highestBidder;
            itemIds[i] = itemList[i].itemId;
        }
        return (itemIds, highestBidders);
    }

    modifier nonOwner() {
        if (msg.sender == owner()) {
            revert OwnerCannotBidOnOwnAuction();
        }
        _;
    }

    // @todo can I combine these two modifiers into one?
    modifier bidAmountGreaterThanStartingPrice(uint _auctionId, uint _itemId) {
        require(
            msg.value > auctions[_auctionId].items[_itemId].startingPrice,
            "Bid amount is less than the starting price."
        );
        _;
    }

    modifier bidAmountGreaterThanHighestBid(uint _auctionId, uint _itemId) {
        require(
            msg.value > auctions[_auctionId].items[_itemId].highestBid,
            "Bid amount is less than the highest bid."
        );
        _;
    }

    modifier bidMustBeValid(uint _auctionId, uint _itemId) {
        require(
            msg.value > auctions[_auctionId].items[_itemId].startingPrice &&
                msg.value > auctions[_auctionId].items[_itemId].highestBid,
            "Bid amount is less than the starting price or the highest bid."
        );
        _;
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

    /**
     * To make testing easier, not recommended for production
     * also Item[] inside Auction is not part of the ABI so we can't access it using mapping
     * see: https://github.com/NomicFoundation/hardhat/issues/2433
     * There is probably a way to do deal with that without using the functions below
     */
    function getAuction(
        uint _auctionId
    ) external view returns (Auctions memory) {
        return auctions[_auctionId];
    }

    function getAuctionItems(
        uint _auctionId
    ) external view returns (Item[] memory) {
        return auctions[_auctionId].items;
    }
}
