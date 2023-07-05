const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Cyborg", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  const initialSupply = 10000;

  async function deployBorgTokenFixture() {
    
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Borg = await ethers.getContractFactory("Cyborg");
    const token = await Borg.deploy(initialSupply);

    return { token, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should assign the total supply of tokens to the owner", async function () {
      const { token, owner } = await loadFixture(deployBorgTokenFixture);

      const total = await token.totalSupply();
      expect(total).to.equal(await token.balanceOf(owner.address));
    });
  });

  describe("Transaction", function () {
    it("Should transfer tokens between accounts with Tax", async function () {
      const { token, owner, otherAccount } = await loadFixture(deployBorgTokenFixture);

        const ownerBalance = await token.balanceOf(owner.address);
      
        await token.transfer(otherAccount.address, 50);
        const addr1Balance = await token.balanceOf(otherAccount.address);
        expect(addr1Balance).to.equal(48);

        const ownerNewBalance = await token.balanceOf(owner.address);
        expect(ownerNewBalance).to.equal(ownerBalance - BigInt(48) );
    });

    it("Should fail if sender doesnt have enough tokens", async function () {
      const { token, owner, otherAccount } = await loadFixture(deployBorgTokenFixture);

      const ownerBalance = await token.balanceOf(owner.address);

      // Transfer 10001 GLD tokens from owner to otherAccount
      await expect(
       token.transfer(otherAccount.address, ownerBalance + BigInt(20))
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });        
  })
});
