// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./SPC_Token.sol";
import "./SPCB_Token.sol";

/// @title Contract for SpendCoin
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra
/// @notice Main token : SpendCoin

contract Gateway {

	address public ownerContract;
	SPC_Token spc_token;
	SPCB_Token spcb_token;

	// Struct snapshot[weekNumber]
	struct DataSnapshot {
		bool exist;
		bool todoCalc;
		uint totalHoldersReward;
		uint totalSpcHolders;
		//uint dotValue;
	}

	uint pcentReward = 2; // pcent reward default : 2%
	uint minimumHolding = 0; // minimum for holder to be holder
	// boucle no holders
	mapping (address => bool) public noHolders;
	address[] noHoldersList;
	//mapping (address => mapping (uint => uint)) totalWeekNoHolder; // week => total
	mapping (uint => uint) totalSpcHolders; // week => total

	mapping (uint => DataSnapshot) public dataSnapshots;
	mapping (address => uint) public accountLastClaim;

	constructor(address _spcContractAddress, address payable _spcbContractAddress) {
		ownerContract = msg.sender;
		spc_token = SPC_Token(_spcContractAddress); // address SPC_Token contract
		spcb_token = SPCB_Token(_spcbContractAddress); // address SPCB_Token contract
	}

	/// @notice calc week number from 01/08/2021
	function getWeekNumber() public view  returns (uint256) {
		return spc_token.calcWeekNumber();
	}

	function existDataSnapshop(uint256 _snapshotId) public view returns (bool) {
		return dataSnapshots[_snapshotId].exist;
	}

	function newSnapshot() public returns (uint256) {
		uint newId = getWeekNumber();
		createDataSnapshot(newId);
		//spc_token.newSnapshot();
		return newId;
	}

	function createDataSnapshot(uint _newId) public returns (bool) {
		if (!existDataSnapshop(_newId)) {
			dataSnapshots[_newId].exist = true;
			dataSnapshots[_newId].todoCalc = true;
			dataSnapshots[_newId].totalHoldersReward = 0;
			// get last snapshot for updating totalHoldersReward ??
			return true;
		}
		return false;
	}

	/// @notice balanceOf SpendCoin
	/// @param _account customer address
	function spcBalanceOf(address _account) public view  returns (uint256) {
		return spc_token.balanceOf(_account);
	}

	//function snapshot() public view {}
	//function getSnapshot(getCurrentSnapshotId()) public view {}

	/// @notice balanceOf SpendCashBack
	/// @param _account customer address
	/// @return balanceOf Account SpendCashBack
	function spcbBalanceOf(address _account) public view  returns (uint256) {
		return spcb_token.balanceOf(_account);
	}

	/// @notice use (burn) SpendCashBack
	/// @param _account customer address
	/// @param _burnAmount amount to burn
	function spcbBurn(address _account, uint _burnAmount) public /* noDapp() */ {
		spcb_token.burn(_account, _burnAmount);
	}

	/// @notice reward SpendCashBack
	/// @param _account customer address
	/// @param _rewardAmount amount to reward
	function spcbReward(address _account, uint _rewardAmount) public /* private */ {
		spcb_token.reward(_account, _rewardAmount);
	}

	/// @notice calc reward SpendCashBack
	/// @param _account customer address
	/// @param _usdcAmount amount to reward
	function calcSpcbReward(address _account, uint _usdcAmount) public /* noDapp() */ {
		uint result = (_usdcAmount * pcentReward) * 10**16;
		spcbReward(_account, result);
		// total reward holder in week
		uint snapshotId = getWeekNumber();
		if (!existDataSnapshop(snapshotId)) {
			snapshotId = newSnapshot();
		}
		dataSnapshots[snapshotId].totalHoldersReward += result;
		// if account is holder
		if (spcBalanceOf(_account) > minimumHolding) {
			spcbReward(_account, result);
		}
	}

	/// @notice add no holder to list
	/// @param _account customer address
	function addNoHolder(address _account) public {
		// check list si already exist
		uint noHoldersListLen = noHoldersList.length;
		bool exist = false;
		for (uint i = 0; i < noHoldersListLen; i++) {
			if(noHoldersList[i] == _account) {
				exist = true;
				break;
			}
		}
		if (!exist) {
			noHoldersList.push(_account);
		}
		noHolders[_account] = true;
	}

	/// @notice suppr no holder to list
	/// @param _account customer address
	function delNoHolder(address _account) public {
		noHolders[_account] = false;
	}

	/// @notice calc claim on all week before last calc claim
	function initClaim() public {
		uint actualWeek = getWeekNumber();

		if (!existDataSnapshop(actualWeek)) {
			createDataSnapshot(actualWeek);
		}

		if(!dataSnapshots[actualWeek].todoCalc) {
			return;
		}

		// boucle no holders sur actualweek
		uint noHoldersListLen = noHoldersList.length;
		uint balanceNoHolder;
		for (uint y = 0; y < noHoldersListLen; y++) {
			if(noHolders[noHoldersList[y]] == true) {
				balanceNoHolder = spcBalanceOf(noHoldersList[y]);
				// check si minimum !!!!
				// total pour semaines precedentes
				for (uint i = actualWeek - 1; i >= 0; i--) {
					if (!existDataSnapshop(i)) {
						createDataSnapshot(i);
					}
					if(!dataSnapshots[i].todoCalc) {
						break;
					}
					// check si minimum !!!!
					totalSpcHolders[i] += balanceNoHolder;
				}
			}
		}

		for (uint i = actualWeek - 1; i >= 0; i--) {
			if (!existDataSnapshop(i)) {
				createDataSnapshot(i);
			}
			if(!dataSnapshots[i].todoCalc) {
				break;
			}
			dataSnapshots[i].totalSpcHolders = spc_token.totalSupply() - totalSpcHolders[i];
			dataSnapshots[i].todoCalc = false;
		}
	}

	/// @notice Holder claim spcb
	function claim() public returns(uint) {
		return holderClaim(msg.sender);
	}

	/// @notice force Holder to claim spcb
	/// @param _account customer address
	function forcedClaim(address _account) public /* noAdmin */ returns(uint) {
		return holderClaim(_account);
	}

	/// @notice Holder claim spcb
	/// @param _account customer address
	function holderClaim(address _account) private returns(uint) {
		// get last week claim
		uint lastWeekClaim = accountLastClaim[_account];
		uint actualWeek = getWeekNumber();
		uint totalClaim = 0;

		// calc claim on all week before last claim
		if (lastWeekClaim == actualWeek) {
			return 0;
		}

		uint balanceHolder = spcBalanceOf(_account);
		// set last week claim
		accountLastClaim[_account] = actualWeek;
		// check si minimum !!!!
		/*
		si semaine 3 mini dans snapshot
		recup mini dans snapshot
		balanceHolder = recup balance de semaine avant
		*/

		// total pour semaines precedentes
		for (uint i = actualWeek - 1; i >= lastWeekClaim; i--) {
			if (!existDataSnapshop(i)) {
				createDataSnapshot(i);
			}
			if(!dataSnapshots[i].todoCalc) {
				// set last week claim
				accountLastClaim[_account] = i;
				break;
			}
			// check si minimum !!!!
			totalClaim += ((balanceHolder * dataSnapshots[i].totalHoldersReward) / dataSnapshots[i].totalSpcHolders);
		}

		spcbReward(_account, totalClaim);
		return totalClaim;
	}
}