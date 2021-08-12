const { expect } = require("chai");

const totalSupply = ethers.utils.parseEther(new String(80 * 10**6).valueOf());
// const totalSupply = "80000000000000000000000000";
let SPC_Token;
let token;
let owner, addr1, addr2, addr3, addrs
let owneraddr;
let contractAsSigner0, contractAsSigner1, contractAsSigner2;

beforeEach(async function () {
  // Get the ContractFactory and Signers here.
  SPC_Token = await ethers.getContractFactory("SPC_Token");
  token = await SPC_Token.deploy();
  await token.deployed();

  [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
  owneraddr = owner.address;
  console.log("owner address: " + owneraddr);

  contractAsSigner0 = token.connect(owner);
  contractAsSigner1 = token.connect(addr1);
  contractAsSigner2 = token.connect(addr2);
});


describe("SPC_Token", function () {
  it("Should return the name", async function () {
    expect(await token.name()).to.equal("SpendCoin");
  });
  
  it("Should return the symbol", async function () {
    expect(await token.symbol()).to.equal("SPC");
  });

  it("Should return the total supply", async function () {
    expect(await token.totalSupply()).to.equal(totalSupply);
    // expect(await token.totalSupply()).to.equal(totalSupply);
    // expect((await token.totalSupply()).toString()).to.equal(totalSupply);
    
    expect(await token.balanceOf(owneraddr)).to.equal(totalSupply);
  });
});
