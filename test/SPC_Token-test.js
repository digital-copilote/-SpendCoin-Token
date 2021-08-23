const { expect } = require("chai");

const totalSupply = ethers.utils.parseEther(new String(80 * 10**6).valueOf());
// const totalSupply = "80000000000000000000000000";
let SPC_Token;
let token;
let owner, addr1, addr2, addr3, addrs
let owneraddr;
let contractAsSigner0, contractAsSigner1, contractAsSigner2;

beforeEach(async function () {
  [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
  owneraddr = owner.address;
  
  // Get the ContractFactory and Signers here.
  SPC_Token = await ethers.getContractFactory("SPC_Token");
  token = await SPC_Token.deploy(owneraddr);
  await token.deployed();

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

  xit("Should return the snapshot id", async function () {
    expect(await token.getCurrentSnapshotId()).to.equal(0);
    // token.snapshot().then(snapshotId => expect(snapshotId).to.equal(0));

    await network.provider.send("evm_increaseTime", [604800+2])
    await network.provider.send("evm_mine") // this one will have 10s more

    const snapshotTx = await token.snapshot();
    // wait until the transaction is mined
    await snapshotTx.wait();
    let snapshotId = await token.getCurrentSnapshotId();
    expect(snapshotId).to.equal(1);
    // expect(snapshotId.toString()).to.equal("1");
    // expect(snapshotId).to.equal(1);
  });
});

/*
    contractAsSigner2.buyTokens(
      {
        value: ethers.utils.parseEther("10.0")
      }
    ).then(async () => expect((await ico.contributorsToTokenAmount(addr3.address)).toString()).to.equal("15000000000000000000000"))
  })

----------

    const finalizeTx = await token.snapshot()

    await finalizeTx.wait();

    expect(await token.getCurrentSnapshotId()).to.equal(1)

*/
