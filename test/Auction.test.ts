import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs';
import { expect } from 'chai';
import { ethers } from 'hardhat';

// @todo remember to use typechain
// import { Auction } from '../typechain/Auction';

const Item = {};

describe('Auction', function () {
  async function deployAuctionFixture() {
    const [owner, bidder1, bidder2] = await ethers.getSigners();

    const Auction = await ethers.getContractFactory('Auction');
    const auction = await Auction.deploy();

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
        auction.connect(bidder1).createAuction(100, 100, 100)
      ).to.be.revertedWith('Ownable: caller is not the owner');
    });
  });
});
