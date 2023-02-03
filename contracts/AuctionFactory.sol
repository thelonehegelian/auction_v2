// SPDX license identifier: UNLICENSED
pragma solidity ^0.8.9;
// import "hardhat/console.sol";

import "./Auction.sol";

contract AuctionFactory {
    address[] public deployedAuctions;

    function createAuction() public {
        address newAuction = address(new Auction());
        deployedAuctions.push(newAuction);
    }

    function getDeployedAuctions() public view returns (address[] memory) {
        return deployedAuctions;
    }
}
