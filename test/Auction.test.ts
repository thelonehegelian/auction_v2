import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';

// @todo remember to use typechain
// @note feels like I am missing something here
import { Auction } from '../typechain-types/Auction';

const Item: Auction.ItemStruct = {
  itemName: 'Item 1',
  itemPrice: 100,
};

describe('Auction', function () {
  async function deployAuctionFixture() {
    const [owner, bidder1, bidder2] = await ethers.getSigners();

    const Auction = await ethers.getContractFactory('Auction');
    const auction: Auction = await Auction.deploy();

    return { auction, owner, bidder1, bidder2 };
  }

  describe('Deployment', function () {
    it('Should owner for contract', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);

      expect(await auction.owner()).to.equal(owner.address);
    });

    // only owner can call the createAuction function
    it('Should only owner can create auction', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);

      await expect(
        auction.connect(bidder1).createAuction(1, Item)
      ).to.be.revertedWith('Only owner can call this function.');
    });

    it('Should create auction', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);

      await auction.createAuction(1, Item);

      const auctionItem = await auction.auctions(1);

      expect(auctionItem.item[0]).to.equal(Item.itemName);
      expect(auctionItem.item[1]).to.equal(Item.itemPrice);
      expect(auctionItem.highestBid).to.equal(Item.itemPrice);
    });
  });
});
