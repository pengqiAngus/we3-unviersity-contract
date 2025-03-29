import { expect } from "chai";
import { ethers } from "hardhat";
import { YiDengToken } from "../../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("YiDengToken", function () {
  let yiDengToken: YiDengToken;
  let owner: SignerWithAddress;
  let teamWallet: SignerWithAddress;
  let marketingWallet: SignerWithAddress;
  let communityWallet: SignerWithAddress;
  let buyer: SignerWithAddress;

  const TOKENS_PER_ETH = 1000;
  const MAX_SUPPLY = 1250000;

  beforeEach(async function () {
    [owner, teamWallet, marketingWallet, communityWallet, buyer] =
      await ethers.getSigners();

    const YiDengToken = await ethers.getContractFactory("YiDengToken");
    yiDengToken = await YiDengToken.deploy();
    await yiDengToken.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await yiDengToken.owner()).to.equal(owner.address);
    });

    it("Should have correct name and symbol", async function () {
      expect(await yiDengToken.name()).to.equal("YiDeng Token");
      expect(await yiDengToken.symbol()).to.equal("YD");
    });
  });

  describe("Initial Distribution", function () {
    it("Should distribute initial tokens correctly", async function () {
      await yiDengToken.distributeInitialTokens(
        teamWallet.address,
        marketingWallet.address,
        communityWallet.address
      );

      expect(await yiDengToken.balanceOf(teamWallet.address)).to.equal(
        MAX_SUPPLY * 0.2
      );
      expect(await yiDengToken.balanceOf(marketingWallet.address)).to.equal(
        MAX_SUPPLY * 0.1
      );
      expect(await yiDengToken.balanceOf(communityWallet.address)).to.equal(
        MAX_SUPPLY * 0.1
      );
    });

    it("Should not allow double distribution", async function () {
      await yiDengToken.distributeInitialTokens(
        teamWallet.address,
        marketingWallet.address,
        communityWallet.address
      );

      await expect(
        yiDengToken.distributeInitialTokens(
          teamWallet.address,
          marketingWallet.address,
          communityWallet.address
        )
      ).to.be.revertedWith("Initial distribution already done");
    });
  });

  describe("Token Purchase", function () {
    it("Should allow users to buy tokens with ETH", async function () {
      const ethAmount = ethers.parseEther("1");
      const expectedTokens = TOKENS_PER_ETH;

      await expect(yiDengToken.connect(buyer).buyWithETH({ value: ethAmount }))
        .to.emit(yiDengToken, "TokensPurchased")
        .withArgs(buyer.address, ethAmount, expectedTokens);

      expect(await yiDengToken.balanceOf(buyer.address)).to.equal(
        expectedTokens
      );
    });

    it("Should not exceed max supply", async function () {
      const largeEthAmount = ethers.parseEther("1251");
      await expect(
        yiDengToken.connect(buyer).buyWithETH({ value: largeEthAmount })
      ).to.be.revertedWith("Would exceed max supply");
    });
  });

  describe("Token Sale", function () {
    beforeEach(async function () {
      // 先购买一些代币
      await yiDengToken
        .connect(buyer)
        .buyWithETH({ value: ethers.parseEther("1") });
    });

    it("Should allow users to sell tokens", async function () {
      const tokenAmount = 500;
      const expectedEthAmount = ethers.parseEther("0.5");

      await yiDengToken.connect(buyer).sellTokens(tokenAmount);

      expect(await yiDengToken.balanceOf(buyer.address)).to.equal(500);
    });

    it("Should not allow selling more tokens than owned", async function () {
      const largeAmount = 2000;
      await expect(
        yiDengToken.connect(buyer).sellTokens(largeAmount)
      ).to.be.revertedWith("Insufficient balance");
    });
  });
});
