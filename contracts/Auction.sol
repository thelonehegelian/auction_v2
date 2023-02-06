// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Auction is Ownable, ReentrancyGuard {
    struct Auctions {
        uint auctionId; // could be useful if there was a factory contract
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

    uint auctionId;

    /*************EVENTS**************/
    // @todo should be indexed for better filtering in the frontend
    event AuctionCreated(uint auctionId, Item item);
    event BidPlaced(uint auctionId, uint256 highestBid, address highestBidder);
    event AuctionEnded(uint auctionId, string auctionName);

    /*************ERRORS**************/
    error OwnerCannotBidOnOwnAuction();
    error AuctionHasNotEnded();
    error AuctionHasEnded();
    error BidAmountIsLessThanStartingPriceOrHighestBid();

    /*************MAIN**************/

    /// @param items - array of items to be auctioned
    /// @param auctionName - name of the auction
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

    /// @param _auctionId - id of the auction
    /// @param _itemId - id of the item
    /// @notice - this function adds balance to the contract
    // don't think reentrancy attack is possible here but to be sure we use the nonReentrant modifier
    // also see comment in the _transferToPrevBidder function
    function placeBid(
        uint _auctionId,
        uint _itemId
    ) public payable nonOwner nonReentrant bidMustBeValid(_auctionId, _itemId) {
        // if the auction time has ended
        if (block.timestamp >= auctions[_auctionId].auctionEndTime) {
            // @note a private _endAuction function can be used take care of the settlement here
            emit AuctionEnded(_auctionId, auctions[_auctionId].auctionName);
            revert AuctionHasEnded();
        }

        address prevHighestBidder = auctions[_auctionId]
            .items[_itemId]
            .highestBidder;
        uint prevHighestBid = auctions[_auctionId].items[_itemId].highestBid;
        // updating states before calling transfer
        auctions[_auctionId].items[_itemId].highestBid = msg.value;
        auctions[_auctionId].items[_itemId].highestBidder = msg.sender;

        emit BidPlaced(auctionId, msg.value, msg.sender);
        // is this check necessary?
        if (prevHighestBidder != address(0)) {
            _transferToPrevBidder(payable(prevHighestBidder), prevHighestBid);
        }
    }

    /// Finds the highest bidder for each item in the auction and returns an array of addresses
    /// @param _auctionId - id of the auction
    /// @return - array of item ids
    /// @return - array of addresses of the highest bidders
    function findHighestBidders(
        uint _auctionId
    ) public view onlyOwner returns (uint[] memory, address[] memory) {
        if (block.timestamp <= auctions[_auctionId].auctionEndTime) {
            revert AuctionHasNotEnded();
        }

        Item[] memory itemList = auctions[_auctionId].items;
        address[] memory highestBidders = new address[](itemList.length);
        uint[] memory itemIds = new uint[](itemList.length);

        for (uint i = 0; i < itemList.length; ) {
            highestBidders[i] = itemList[i].highestBidder;
            itemIds[i] = itemList[i].itemId;
            unchecked {
                i += 1;
            }
        }
        return (itemIds, highestBidders);
    }

    /*************MODIFIERS**************/
    modifier nonOwner() {
        if (msg.sender == owner()) {
            revert OwnerCannotBidOnOwnAuction();
        }
        _;
    }

    modifier bidMustBeValid(uint _auctionId, uint _itemId) {
        if (
            msg.value < auctions[_auctionId].items[_itemId].startingPrice ||
            msg.value < auctions[_auctionId].items[_itemId].highestBid
        ) {
            // though starting price and highest bid are the same in our example
            revert BidAmountIsLessThanStartingPriceOrHighestBid();
        }
        _;
    }

    /*************HELPERS**************/
    /// @param _prevBidder - address of the previous highest bidder
    /// @param prevHighestBid - amount of the previous highest bid
    // is reentrancy attack possible here? this is a private function so it should be okay
    // also currently contract would have balance only contributed by the previous bidder
    // so more balance than that cannot be taken out
    function _transferToPrevBidder(
        address payable _prevBidder,
        uint prevHighestBid
    ) private {
        _prevBidder.transfer(prevHighestBid);
    }

    /// @param _itemsList - array of items to be auctioned
    function _createItemList(Item[] memory _itemsList) private {
        for (uint i = 0; i < _itemsList.length; ) {
            auctions[auctionId].items.push(_itemsList[i]);
            unchecked {
                i += 1;
            }
        }
    }

    /*************TEST HELPERS**************/
    /**
     * To make testing easier, not recommended for production
     * also Item[] inside Auction is not part of the ABI so we can't access it using mapping
     * see: https://github.com/NomicFoundation/hardhat/issues/2433
     * There is probably a way to do deal with that without using the functions below
     */

    /// @param _auctionId - id of the auction
    function getAuction(
        uint _auctionId
    ) external view returns (Auctions memory) {
        return auctions[_auctionId];
    }

    /// @param _auctionId - id of the auction
    function getAuctionItems(
        uint _auctionId
    ) external view returns (Item[] memory) {
        return auctions[_auctionId].items;
    }
}
