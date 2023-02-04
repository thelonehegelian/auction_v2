import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Auction } from '../typechain-types/contracts/Auction';
import { BigNumber } from 'ethers';

// @todo remember to use typechain
// @note feels like I am missing something here
// @note currently only concerned with a single auction
// @note also possible to use hardhat-deploy
// @note be careful not to reuse variables
// @todo update revert messages
// @todo turn on ESLint

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

// @note For ERC20 token we can either get tokens from whale address or do a storage hack

describe('Auction', function () {
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

    it('Should not allow bid less than highest bid', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      await auction.createAuction(items, auctionName);
      await expect(auction.connect(bidder1).placeBid(0, 1, { value: 100 })).to
        .be.reverted;
    });

    // @todo fix this
    it('Should allow bid greater than highest bid', async function () {
      const { auction, bidder1, bidder2 } = await loadFixture(
        deployAuctionFixture
      );
      const firstBidderOriginalBalance = await ethers.provider.getBalance(
        bidder1.address
      );
      await auction.createAuction(items, auctionName);
      await auction.connect(bidder1).placeBid(0, 1, { value: 110 });
      await auction.connect(bidder2).placeBid(0, 1, { value: 120 });
      // new highest bidder is bidder2
      const newHighestBidder = await auction.getAuctionItems(0);
      expect(newHighestBidder[1].highestBidder).to.equal(bidder2.address);

      // bidder1 balance should be close to original balance after gas fees
      const firstBidderNewBalance = await ethers.provider.getBalance(
        bidder1.address
      );
      expect(firstBidderNewBalance).to.be.closeTo(
        firstBidderOriginalBalance,
        BigNumber.from(1000000000000000)
      );
    });

    it('Should not allow bid after auction end time', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      const now = await time.latest(); // @note do I need this?
      const twoDays = 172800;

      await auction.createAuction(items, auctionName);

      // increase time to two days after auction end time
      await time.increase(now + twoDays);
      await expect(auction.connect(bidder1).placeBid(0, 1, { value: 101 })).to
        .be.reverted;
    });
  });
});
