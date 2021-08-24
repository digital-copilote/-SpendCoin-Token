const { expect } = require("chai");

const totalSupply = ethers.utils.parseEther(new String(80 * 10**6).valueOf());
// const totalSupply = "80000000000000000000000000";
let SPC_Token;
let token;
let owner, addr1, addr2, addr3, addrs
let owneraddr;
let contractAsSigner0, contractAsSigner1, contractAsSigner2;
let period = 604800;

async function avance1Week() {
	await network.provider.send("evm_increaseTime", [period+2])
	await network.provider.send("evm_mine") // this one will have 10s more
}

beforeEach(async function () {
	[owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
	owneraddr = owner.address;
	
	// Get the ContractFactory and Signers here.
	SPC_Token = await ethers.getContractFactory("SPC_Token");
	token = await SPC_Token.deploy(owneraddr);
	await token.deployed();

	// console.log("owner address: " + owneraddr);

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

	it("Should return the weekNumber", async function () {
		expect(await token.calcWeekNumber()).to.equal(0);

		await avance1Week();

		expect(await token.calcWeekNumber()).to.equal(1);
		
	});
	
	it("Test snapshot exist", async function () {
		expect(await token.existSnapshot(0)).to.be.true;

		const snapshotTx = await token.newSnapshot();
		// wait until the transaction is mined
		await snapshotTx.wait();

		expect(await token.existSnapshot(0)).to.be.true;

	});
	
	it("Test snapshot balanceOfAt", async function () {
		//balance after mint is still equal 0
		let balanceOf = await token.balanceOfAt(owneraddr, 0);
		expect(balanceOf[0]).to.be.true;
		expect(balanceOf[1]).to.equal(0);
		//expect(await token.minValueOfAt(owneraddr, 0)).to.equal(0);
		let minValueOf = await token.minValueOfAt(owneraddr, 0);
		expect(minValueOf[0]).to.be.true;
		expect(minValueOf[1]).to.equal(0);

		await avance1Week();

		let snapshotTx = await token.transfer(addr1.address, ethers.utils.parseEther("50.0"));
		// wait until the transaction is mined
		await snapshotTx.wait();

		balanceOf = await token.balanceOfAt(owneraddr, 1);
		expect(balanceOf[0]).to.be.true;
		expect(balanceOf[1]).to.equal("80000000000000000000000000");
		//expect(await token.minValueOfAt(owneraddr, 1)).to.equal("79999950000000000000000000");
		minValueOf = await token.minValueOfAt(owneraddr, 1);
		expect(minValueOf[0]).to.be.true;
		expect(minValueOf[1]).to.equal("79999950000000000000000000");

		balanceOf = await token.balanceOfAt(addr1.address, 1);
		expect(balanceOf[0]).to.be.true;
		expect(balanceOf[1]).to.equal("0");
		
		//expect(await token.minValueOfAt(addr1.address, 1)).to.equal("50");
		minValueOf = await token.minValueOfAt(addr1.address, 1);
		expect(minValueOf[0]).to.be.true;
		expect(minValueOf[1]).to.equal(0);
		expect(await token.balanceOf(addr1.address)).to.equal("50000000000000000000");

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
