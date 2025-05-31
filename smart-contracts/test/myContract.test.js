const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyContract", function () {
  let myContract;

  beforeEach(async function () {
    const MyContract = await ethers.getContractFactory("MyContract");
    myContract = await MyContract.deploy("Initial value"); // already deployed
  });

  it("should set the initial value correctly", async function () {
    expect(await myContract.getValue()).to.equal("Initial value");
  });

  it("should update the value", async function () {
    await myContract.setValue("New value");
    expect(await myContract.getValue()).to.equal("New value");
  });
});
