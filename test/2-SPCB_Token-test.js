const { expect } = require("chai");

let SPCB_Token;
let token;
let owner, addr1, addr2, addr3, addrs
let owneraddr;
let contractAsSigner0, contractAsSigner1, contractAsSigner2;

beforeEach(async function () {
	[owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
	owneraddr = owner.address;
	
	// Get the ContractFactory and Signers here.
	SPCB_Token = await ethers.getContractFactory("SPCB_Token");
	token = await SPCB_Token.deploy();
	await token.deployed();

	// console.log("owner address: " + owneraddr);

	contractAsSigner0 = token.connect(owner);
	contractAsSigner1 = token.connect(addr1);
	contractAsSigner2 = token.connect(addr2);
});

describe("SPCB_Token", function () {
	it("Should return the name", async function () {
		expect(await token.name()).to.equal("SpendCoinBack");
	});

	it("Should return the symbol", async function () {
		expect(await token.symbol()).to.equal("SPCB");
	});

	it("Should return the total supply", async function () {
		expect(await token.totalSupply()).to.equal(0);
	});

	it("Should reward the amount", async function () {
		/* balanceof / totalsupply / reward / balanceof / totalsupply */
		const balance = await token.balanceOf(addr1.address);
		const totalSupply = await token.totalSupply();
		const rewarding = 10;

		const rewardTx = await token.reward(addr1.address, rewarding);
		await rewardTx.wait();

		expect(await token.balanceOf(addr1.address)).to.equal(balance + rewarding);
		expect(await token.totalSupply()).to.equal(totalSupply + rewarding);
		
	});
	
	it("Should burn the amount", async function () {
		/* reward / burn / balanceof / totalsupply */
		const rewarding = 10;

		const rewardTx = await token.reward(addr1.address, rewarding);
		await rewardTx.wait();

		const burnTx = await token.burn(addr1.address, 5);
		await burnTx.wait();

		expect(await token.balanceOf(addr1.address)).to.equal(5);
		expect(await token.totalSupply()).to.equal(5);
	});

	it("Should revert burn", async function () {
		await expect(token.burn(addr1.address, 5)).to.be.reverted;
	});
});
