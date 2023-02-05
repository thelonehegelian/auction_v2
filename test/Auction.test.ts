import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Auction } from '../typechain-types/contracts/Auction';
import { BigNumber } from 'ethers';

// @note currently only concerned with a single auction

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

const BID_AMOUNT_ONE = ethers.utils.parseEther('125');
const BID_AMOUNT_TWO = ethers.utils.parseEther('150');
const ACCOUNT_BALANCE = ethers.utils.parseEther('10000'); // 10,000 ETH for testing in hardhat

describe('Auction', function () {
  // @note also possible to use hardhat-deploy
  async function deployAuctionFixture() {
    const [owner, bidder1, bidder2, bidder3] = await ethers.getSigners();

    const Auction = await ethers.getContractFactory('Auction');
    const auction = await Auction.deploy();

    return { auction, owner, bidder1, bidder2, bidder3 };
  }

  describe('Deployment', function () {
    beforeEach(async function () {
      console.log('=========================================================');
    });

    it('should set deployer as owner of contract', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      expect(await auction.owner()).to.equal(owner.address);
    });

    it('should only allow owner of the contract to create auctions', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      await expect(auction.connect(bidder1).createAuction(items, auctionName))
        .to.be.reverted;
    });

    it('should create an auction', async function () {
      const { auction } = await loadFixture(deployAuctionFixture);

      await auction.createAuction(items, auctionName);
      const auctionItems = await auction.getAuctionItems(0);

      const itemName = auctionItems[0].itemName;
      expect(itemName).to.equal(items[0].itemName);
    });

    it('should not allow auction creator to bid', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      await auction.createAuction(items, auctionName);
      await expect(
        auction.connect(owner).placeBid(0, 1, { value: BID_AMOUNT_ONE })
      ).to.be.reverted;
    });

    it('should not allow bids less than or equal to highest bid or the starting price', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      await auction.createAuction(items, auctionName);
      await expect(auction.connect(bidder1).placeBid(0, 1, { value: 90 })).to.be
        .reverted;
    });

    it('should update a higher bid and the bidder', async function () {
      const { auction, bidder1, bidder2 } = await loadFixture(
        deployAuctionFixture
      );
      await auction.createAuction(items, auctionName);
      await auction.connect(bidder1).placeBid(0, 1, { value: BID_AMOUNT_ONE });
      const gasPrice = await ethers.provider.getGasPrice();
      const gasFee = gasPrice.mul(BigNumber.from(23000));

      // bidder1 balance should have reduced
      let bidder1BalanceBefore = await bidder1.getBalance();
      expect(bidder1BalanceBefore).to.lte(ACCOUNT_BALANCE.sub(BID_AMOUNT_ONE));

      let activeAuction = await auction.getAuction(0);
      let highestBidItem2 = activeAuction.items[1].highestBid;
      expect(highestBidItem2).to.equal(BID_AMOUNT_ONE);
      await auction.connect(bidder2).placeBid(0, 1, { value: BID_AMOUNT_TWO });
      activeAuction = await auction.getAuction(0);
      highestBidItem2 = activeAuction.items[1].highestBid;
      expect(highestBidItem2).to.equal(BID_AMOUNT_TWO);

      // bidder1 should have been refunded, i am not taking precisse gas fee into account and dust into account here
      const bidder1Balance = await bidder1.getBalance();
      expect(bidder1Balance).to.gte(bidder1BalanceBefore);
    });

    it('should not allow bids after auction end time', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      const now = await time.latest();
      const twoDays = 172800;

      await auction.createAuction(items, auctionName);

      // increase time to two days after auction end time
      await time.increase(now + twoDays);
      await expect(
        auction.connect(bidder1).placeBid(0, 1, { value: BID_AMOUNT_ONE })
      ).to.be.reverted;
    });

    it('should not allow settlement if the auction has not ended', async function () {
      const { auction, owner, bidder1 } = await loadFixture(
        deployAuctionFixture
      );
      await auction.createAuction(items, auctionName);
      // unauthorized user should not be able to settle
      await expect(auction.connect(bidder1).findHighestBidders(0)).to.be
        .reverted;

      await expect(auction.connect(owner).findHighestBidders(0)).to.be.reverted;
      // after auction end time should be able to settle
      const now = await time.latest();
      const twoDays = 172800;
      await time.increase(now + twoDays);
      await expect(auction.findHighestBidders(0)).to.not.be.reverted;
    });

    it('should get highest bidders', async function () {
      const { auction, bidder1, bidder2, bidder3 } = await loadFixture(
        deployAuctionFixture
      );
      await auction.createAuction(items, auctionName);
      await auction.connect(bidder1).placeBid(0, 0, { value: BID_AMOUNT_ONE });
      await auction.connect(bidder2).placeBid(0, 1, { value: BID_AMOUNT_TWO });
      await auction.connect(bidder3).placeBid(0, 2, { value: BID_AMOUNT_ONE });

      // end the auction
      const now = await time.latest();
      const twoDays = 172800;
      await time.increase(now + twoDays);

      const highestBidders = await auction.findHighestBidders(0);
      expect(highestBidders[1][0]).equal(bidder1.address);
      expect(highestBidders[1][1]).equal(bidder2.address);
      expect(highestBidders[1][2]).equal(bidder3.address);
    });
  });
});
