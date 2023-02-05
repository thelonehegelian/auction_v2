import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Auction } from '../typechain-types/contracts/Auction';
import { BigNumber } from 'ethers';

// @note feels like I am missing something here
// @note currently only concerned with a single auction
// @note be careful not to reuse variables

const auctionName = 'Worst Mistakes of Your Life';
// sample items for testing
const items = [
  {
    itemId: BigNumber.from(0),
    itemName: 'When you were born',
    startingPrice: BigNumber.from(100),
    highestBid: BigNumber.from(100),
    highestBidder: '0x0000000000000000000000000000000000000000',
  },
  {
    itemId: BigNumber.from(1),
    itemName: 'The day you wore that shirt',
    startingPrice: BigNumber.from(100),
    highestBid: BigNumber.from(100),
    highestBidder: '0x0000000000000000000000000000000000000000',
  },
  {
    itemId: BigNumber.from(2),
    itemName: 'The day of your graduation',
    startingPrice: BigNumber.from(100),
    highestBid: BigNumber.from(100),
    highestBidder: '0x0000000000000000000000000000000000000000',
  },
];

const BID_AMOUNT = ethers.utils.parseEther('125');

describe('Auction', function () {
  // @note also possible to use hardhat-deploy
  async function deployAuctionFixture() {
    const [owner, bidder1, bidder2] = await ethers.getSigners();

    const Auction = await ethers.getContractFactory('Auction');
    const auction = await Auction.deploy();

    return { auction, owner, bidder1, bidder2 };
  }

  describe('Deployment', function () {
    it('Should creator as owner of contract', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      expect(await auction.owner()).to.equal(owner.address);
    });

    it('Should only allow owner of the contract to create auctions', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      await expect(auction.connect(bidder1).createAuction(items, auctionName))
        .to.be.reverted;
    });

    it('Should create an auction', async function () {
      const { auction } = await loadFixture(deployAuctionFixture);

      await auction.createAuction(items, auctionName);
      const auctionItems = await auction.getAuctionItems(0);

      const itemName = auctionItems[0].itemName;
      expect(itemName).to.equal(items[0].itemName);
    });

    it('Should not allow owner/bid creator to bid', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      await auction.createAuction(items, auctionName);
      await expect(auction.connect(owner).placeBid(0, 1, { value: 101 })).to.be
        .reverted;
    });

    it('Should not allow bid less than or equal to highest bid or the starting price', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      await auction.createAuction(items, auctionName);
      await expect(auction.connect(bidder1).placeBid(0, 1, { value: 90 })).to.be
        .reverted;
    });

    it('Should update higher bid and bidder', async function () {
      const { auction, bidder1, bidder2 } = await loadFixture(
        deployAuctionFixture
      );
      await auction.createAuction(items, auctionName);
      await auction.connect(bidder1).placeBid(0, 1, { value: 110 });
      let activeAuction = await auction.getAuction(0);
      let highestBidItem2 = activeAuction.items[1].highestBid;
      expect(highestBidItem2).to.equal(110);
      await auction.connect(bidder2).placeBid(0, 1, { value: 120 });
      activeAuction = await auction.getAuction(0);
      highestBidItem2 = activeAuction.items[1].highestBid;
      expect(highestBidItem2).to.equal(120);
    });

    it('Should not allow bid after auction end time', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      const now = await time.latest();
      const twoDays = 172800;

      await auction.createAuction(items, auctionName);

      // increase time to two days after auction end time
      await time.increase(now + twoDays);
      await expect(auction.connect(bidder1).placeBid(0, 1, { value: 101 })).to
        .be.reverted;
    });
  });
});
