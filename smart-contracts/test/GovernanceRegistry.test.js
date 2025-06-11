const { expect } = require("chai");
const { ethers }  = require("hardhat");

describe("GovernanceRegistry", function () {
  let Registry, registry;
  let owner, addr1, addr2;

  beforeEach(async () => {
    [owner, addr1, addr2] = await ethers.getSigners();
    Registry = await ethers.getContractFactory("GovernanceRegistry");
    registry = await Registry.connect(owner).deploy();
    await registry.deployed();
  });

  it("should set deployer as owner and authorize them", async () => {
    expect(await registry.owner()).to.equal(owner.address);
    expect(await registry.authorizedEntities(owner.address)).to.be.true;
  });

  it("owner can transfer ownership", async () => {
    await expect(registry.connect(owner).transferOwnership(addr1.address))
      .to.emit(registry, "OwnershipTransferred")
      .withArgs(owner.address, addr1.address);

    expect(await registry.owner()).to.equal(addr1.address);
  });

  it("non-owner cannot transfer ownership", async () => {
    await expect(
      registry.connect(addr1).transferOwnership(addr2.address)
    ).to.be.revertedWith("GovernanceRegistry: caller is not the owner");
  });

  it("owner can authorize and deauthorize entities", async () => {
    await expect(registry.connect(owner).setEntityAuthorization(addr1.address, true))
      .to.emit(registry, "EntityAuthorized")
      .withArgs(addr1.address, true);
    expect(await registry.authorizedEntities(addr1.address)).to.be.true;

    await expect(registry.connect(owner).setEntityAuthorization(addr1.address, false))
      .to.emit(registry, "EntityAuthorized")
      .withArgs(addr1.address, false);
    expect(await registry.authorizedEntities(addr1.address)).to.be.false;
  });

  it("only authorized entity can set parameters", async () => {
    const key   = ethers.utils.id("some_key");
    const value = "some_value";

    // addr1 not yet authorized → should revert
    await expect(
      registry.connect(addr1).setParameter(key, value)
    ).to.be.revertedWith("GovernanceRegistry: caller is not authorized");

    // authorize addr1
    await registry.connect(owner).setEntityAuthorization(addr1.address, true);

    // now it works
    await expect(registry.connect(addr1).setParameter(key, value))
      .to.emit(registry, "ParameterSet")
      .withArgs(key, value);

    expect(await registry.getParameter(key)).to.equal(value);
  });

  it("getParameter returns empty string for unset key", async () => {
    const key = ethers.utils.id("unset_key");
    expect(await registry.getParameter(key)).to.equal("");
  });
});
