const { expect } = require("chai");

let contractGateway;
let gateway;
let SPC_Token;
let spc_token;
let SPCB_Token;
let spcb_token;

let owneraddr;
let owner, addr1, addr2, addr3, addrs
let contractAsSigner0, contractAsSigner1, contractAsSigner2;

beforeEach(async function () {
	[owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
	owneraddr = owner.address;

	SPC_Token = await ethers.getContractFactory("SPC_Token");
	spc_token = await SPC_Token.deploy(owneraddr);
	await spc_token.deployed();

	SPCB_Token = await ethers.getContractFactory("SPCB_Token");
	spcb_token = await SPCB_Token.deploy();
	await spcb_token.deployed();

	contractGateway = await ethers.getContractFactory("Gateway");
	gateway = await contractGateway.deploy(spc_token.address, spcb_token.address);
	await gateway.deployed();
	//console.log("gateway address: " + gateway.address);

	contractAsSigner0 = gateway.connect(owner);
	contractAsSigner1 = gateway.connect(addr1.address);
	contractAsSigner2 = gateway.connect(addr2);

	//console.log("********************************");
});

describe("Gateway SPC", function () {
	it("Should return the SPC balance", async function () {
	  expect(await gateway.spcBalanceOf(contractAsSigner0.address)).to.equal(0);
	});
});

describe("Gateway SPCB", function () {
	it("Should return the SPCB balance", async function () {
		expect(await gateway.spcbBalanceOf(contractAsSigner0.address)).to.equal(0);
	});

	it("Should reward the amount", async function () {
		const balance = await gateway.spcbBalanceOf(contractAsSigner1.address);
		const rewarding = 10;
	
		const rewardTx = await gateway.spcbReward(contractAsSigner1.address, rewarding);
		await rewardTx.wait();
	
		expect(await gateway.spcbBalanceOf(contractAsSigner1.address)).to.equal(balance + rewarding);
	});

	it("Should burn the amount", async function () {
		/* reward / burn / balanceof / totalsupply */
		const rewarding = 10;
	
		const rewardTx = await gateway.spcbReward(addr1.address, rewarding);
		await rewardTx.wait();
	
		const burnTx = await gateway.spcbBurn(addr1.address, 5);
		await burnTx.wait();
	
		expect(await gateway.spcbBalanceOf(addr1.address)).to.equal(5);
	});
	
});

describe("Gateway functions", function () {
	it("Should return the weekNumber", async function () {
		expect(await gateway.getWeekNumber()).to.equal(0);
	});
	
	it("Should create the snapshot in gateway", async function () {
		const calcReward = await gateway.calcSpcbReward(addr1.address, 100);
		await calcReward.wait();

		const weekNumber = await gateway.getWeekNumber();
		expect(await gateway.existDataSnapshop(weekNumber)).to.be.true;
	});
	
	it("calc SPCB reward no holder", async function () {
		// calc reward for 100 usbc
		const calcReward = await gateway.calcSpcbReward(addr1.address, 100);
		await calcReward.wait();

		expect(await gateway.spcbBalanceOf(addr1.address)).to.equal("2000000000000000000");
	});

	it("calc SPCB reward with holder", async function () {
		// transfert 100 spc from owneraddr
		const rewardTx = await spc_token.transfer(addr1.address, 100);
		await rewardTx.wait();
	
		// calc reward for 100 usbc
		const calcReward = await gateway.calcSpcbReward(addr1.address, 100);
		await calcReward.wait();

		expect(await gateway.spcbBalanceOf(addr1.address)).to.equal("4000000000000000000");

	});
	it("calc reward check totalHoldersReward", async function () {
		// calc reward for 100 usbc
		const calcReward = await gateway.calcSpcbReward(addr1.address, 100);
		await calcReward.wait();

		const weekNumber = await gateway.getWeekNumber();
		const dataSnapshot = await gateway.dataSnapshots(weekNumber);
		expect(dataSnapshot[2]).to.equal("2000000000000000000");
	});
	it("add no Holder to list", async function () {
		// add no holder
		const addNoHolder = await gateway.addNoHolder(addr1.address);
		await addNoHolder.wait();

		const noHolder = await gateway.noHolders(addr1.address);
		expect(noHolder).to.be.true;
	});
	it("suppr no Holder in list", async function () {
		// add no holder
		const addNoHolder = await gateway.addNoHolder(addr1.address);
		await addNoHolder.wait();

		let noHolder = await gateway.noHolders(addr1.address);
		expect(noHolder).to.be.true;

		const delNoHolder = await gateway.delNoHolder(addr1.address);
		await delNoHolder.wait();

		noHolder = await gateway.noHolders(addr1.address);
		expect(noHolder).to.be.false;

	});
	xit("init claim", async function () {
	});
	xit("force claim", async function () {
	});

		//console.log("********************************");

});