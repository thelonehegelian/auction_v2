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

    struct AuctionDetails {
        uint auctionId;
        Item item;
    }
    struct Item {
        uint itemId;
        string itemName;
        uint256 itemPrice;
    }

    constructor() {
        owner = msg.sender;
    }

    function createAuction(string[] memory _auctionDetails) public onlyOwner {}

    function placeBids() public {}

    // onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function findHighestBidder() private {}
}
