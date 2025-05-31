const { expect } = require("chai");

describe("MyContract", function () {
  let MyContract;
  let myContract;
  let owner;
  let otherAccount;

  beforeEach(async function () {
    [owner, otherAccount] = await ethers.getSigners();
    MyContract = await ethers.getContractFactory("MyContract");
    myContract = await MyContract.deploy(42);
    await myContract.deployed();
  });

  it("should set the initial value correctly", async function () {
    expect(await myContract.getValue()).to.equal(42);
  });

  it("should return the correct owner", async function () {
    expect(await myContract.getOwner()).to.equal(owner.address);
  });

  it("should allow the owner to set a new value", async function () {
    await myContract.setValue(100);
    expect(await myContract.getValue()).to.equal(100);
  });

  it("should emit an event when value is set", async function () {
    await expect(myContract.setValue(77))
      .to.emit(myContract, "ValueSet")
      .withArgs(77, owner.address);
  });

  it("should not allow non-owners to set value", async function () {
    await expect(
      myContract.connect(otherAccount).setValue(55)
    ).to.be.revertedWith("Only owner can call this");
  });
});
