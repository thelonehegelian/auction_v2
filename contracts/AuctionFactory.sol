// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
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
