import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Auction } from '../typechain-types/Auction';

// @todo remember to use typechain
// @note feels like I am missing something here
// @note currently only concerned with a single auction
// @note also possible to use hardhat-deploy
// @note be careful not to reuse variables
// @todo update revert messages
// @todo turn on ESLint

// sample item for testing
const Item: Auction.ItemStruct = {
  itemName: 'Movie Ticket',
  itemPrice: 100,
};

const Auction = {
  auctionId: 0,
  auctionName: 'Worst Mistakes of Your Life',
  item: Item,
};

const BID_AMOUNT = ethers.utils.parseEther('125');

// @note For ERC20 token we can either get tokens from whale address or do a storage hack

describe('Auction', function () {
  async function deployAuctionFixture() {
    const [owner, bidder1, bidder2] = await ethers.getSigners();

    const Auction = await ethers.getContractFactory('Auction');
    const auction: Auction = await Auction.deploy();

    return { auction, owner, bidder1, bidder2 };
  }

  describe('Deployment', function () {
    it('Should creator as owner of contract', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      expect(await auction.owner()).to.equal(owner.address);
    });

    it('Should only allow owner of the contract to create auctions', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);

      await expect(
        auction.connect(bidder1).createAuction(1, Item)
      ).to.be.revertedWith('Only owner can call this function.');
    });

    it('Should create an auction', async function () {
      const { auction } = await loadFixture(deployAuctionFixture);

      await auction.createAuction(1, Item);

      const auctionItem = await auction.auctions(1);

      expect(auctionItem.item[0]).to.equal(Item.itemName);
      expect(auctionItem.item[1]).to.equal(Item.itemPrice);
      expect(auctionItem.highestBid).to.equal(Item.itemPrice);
    });

    it('Should not allow owner/bid creator to bid', async function () {
      const { auction, owner } = await loadFixture(deployAuctionFixture);
      await auction.createAuction(1, Item);
      await expect(
        auction.connect(owner).placeBid(1, { value: 101 })
      ).to.be.revertedWith('Owner cannott bid on their own auction.');
    });

    it('Should not allow bid less than highest bid', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      await auction.createAuction(1, Item);
      await expect(
        auction.connect(bidder1).placeBid(1, { value: 100 })
      ).to.be.revertedWith('Your bid is lower than the highest bid.');
    });

    it('Should allow bid greater than highest bid', async function () {
      const { auction, bidder1, bidder2 } = await loadFixture(
        deployAuctionFixture
      );
      const firstBidderOriginalBalance = await ethers.provider.getBalance(
        bidder1.address
      );

      await auction.createAuction(1, Item);
      await auction.connect(bidder1).placeBid(1, { value: BID_AMOUNT });

      const auctionItem = await auction.auctions(1);
      // contract balance and highest bid should be equal now
      const contractBalance = await ethers.provider.getBalance(auction.address);
      expect(contractBalance).to.equal(auctionItem.highestBid); // !annoying big numbers!
      // highest bid should be updated
      expect(auctionItem.highestBid).to.equal(BID_AMOUNT);
      // bidder should be updated
      expect(auctionItem.highestBidder).to.equal(bidder1.address);

      await auction
        .connect(bidder2)
        .placeBid(1, { value: ethers.utils.parseEther('150') });
      // bidder2 should be the highest bidder now and bidder1 should get their money back
      const auctionItemAfter = await auction.auctions(1);
      expect(auctionItemAfter.highestBidder).to.equal(bidder2.address);
      const firstBidderBalanceAfter = await ethers.provider.getBalance(
        bidder1.address
      );
      expect(firstBidderOriginalBalance).to.closeTo(
        firstBidderBalanceAfter,
        1000000000000000000n // @note bad practice
      );
    });

    it('Should not allow bid after auction end time', async function () {
      const { auction, bidder1 } = await loadFixture(deployAuctionFixture);
      const now = await time.latest(); // @note do I need this?
      const twoDays = 172800;

      await auction.createAuction(1, Item);

      // increase time to two days after auction end time
      await time.increase(now + twoDays);
      await expect(
        auction.connect(bidder1).placeBid(1, { value: 101 })
      ).to.be.revertedWith('Auction has ended.');
    });
  });
});
