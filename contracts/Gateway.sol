// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./SPC_Token.sol";
import "./SPCB_Token.sol";
import "./SwapSpendCoin.sol";

/// @title Contract for SpendCoin
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra
/// @notice Main token : SpendCoin

contract Gateway is SwapSpendCoinTest {

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

	uint pcentShopperReward = 2; // pcent reward default : 2%
	uint pcentShopperBonusReward = 2; // pcent reward default : 2%
	uint pcentHoldersReward = 2; // pcent reward default : 2%
	uint minimumHolding = 0; // minimum for holder to be holder

	// define list of excluded holders not to reward 
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

	function buyWithToken(address _tokenIn, uint _amountOut, uint _spcbAmount) public {
		// tester la balance SPCB
		uint spcbBalance = spcbBalanceOf(msg.sender);
		require(spcbBalance >= _spcbAmount, "Insufficient SPCB balance");
		
		uint spcbAmountUsed = _spcbAmount;
		// burn
		if (_amountOut < _spcbAmount) {
			spcbAmountUsed = _amountOut;
		}
		spcbBurn(msg.sender, spcbAmountUsed);
		
		if (_amountOut >= _spcbAmount) {
			// recalculer le amount USDC net de remise achat
			uint usdcAmount = _amountOut - _spcbAmount;

			// Swap
			swapToken(_tokenIn, usdcAmount);
		}

		// reward
		calcSpcbReward(msg.sender, _amountOut);
	}

	function buyWithETH(uint _amountOut, uint _spcbAmount) public payable {
		// tester la balance SPCB
		uint spcbBalance = spcbBalanceOf(msg.sender);
		require(spcbBalance >= _spcbAmount, "Insufficient SPCB balance");
		
		uint spcbAmountUsed = _spcbAmount;
		// burn
		if (_amountOut < _spcbAmount) {
			spcbAmountUsed = _amountOut;
		}
		spcbBurn(msg.sender, spcbAmountUsed);
		
		if (_amountOut >= _spcbAmount) {
			// recalculer le amount USDC net de remise achat
			uint usdcAmount = _amountOut - _spcbAmount;

			// Swap
			swapETH(usdcAmount);
		}

		// reward
		calcSpcbReward(msg.sender, _amountOut);
	}

	/// @notice calc week number from 01/08/2021
	function getWeekNumber() public view  returns (uint256) {
		return spc_token.calcWeekNumber();
	}

	function existDataSnapshot(uint256 _snapshotId) public view returns (bool) {
		return dataSnapshots[_snapshotId].exist;
	}

	function newDataSnapshot() public returns (uint256) {
		uint newId = getWeekNumber();
		createDataSnapshot(newId);
		//spc_token.newSnapshot();
		return newId;
	}

	function createDataSnapshot(uint _newId) public returns (bool) {
		if (!existDataSnapshot(_newId)) {
			dataSnapshots[_newId].exist = true;
			dataSnapshots[_newId].todoCalc = true;
			dataSnapshots[_newId].totalHoldersReward = 0;
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
	function spcbBurn(address _account, uint _burnAmount) public /* onlyDapp() */ {
		spcb_token.burn(_account, _burnAmount);
	}

	/// @notice reward SpendCashBack
	/// @param _account customer address
	/// @param _rewardAmount amount to reward
	function spcbReward(address _account, uint _rewardAmount) public /* private */ {
		spcb_token.reward(_account, _rewardAmount);
	}

	/// @notice Explain to an end user what this does
	/// @param _account customer address
	/// @dev Explain to a developer any extra details
	/// @return the minimum holded balance during last snapshot
	function spcHoldedBalanceOf(address _account) public view returns (uint) {
		uint snapshotId = getWeekNumber();
		if (snapshotId == 0) {
			return 0;
		}
		(bool boolmin, uint minValueOf) = spc_token.minValueOfAt(_account, snapshotId - 1);
		if (boolmin) {
			return minValueOf;
		} else {
			(bool boolBal, uint balanceOfAt) = spc_token.balanceOfAt(_account, snapshotId);
			if (boolBal) {
				return balanceOfAt;
			}
			return spcBalanceOf(_account);
		}
	}

	/// @notice calc reward SpendCashBack
	/// @param _account shopper address
	/// @param _usdcAmount amount to reward
	function calcSpcbReward(address _account, uint _usdcAmount) public /* onlyDapp() */ {
		// reward shopper
		uint result = (_usdcAmount * pcentShopperReward) / 100;
		spcbReward(_account, result);

		// if shopper is holder
		result = (_usdcAmount * pcentShopperBonusReward) / 100;
		uint holdedBalance = spcHoldedBalanceOf(_account);
		if (holdedBalance > minimumHolding) {
			spcbReward(_account, result);
		}
		
		// total reward holder in week
		uint snapshotId = getWeekNumber();
		if (!existDataSnapshot(snapshotId)) {
			snapshotId = newDataSnapshot();
		}
		result = (_usdcAmount * pcentHoldersReward) / 100;
		dataSnapshots[snapshotId].totalHoldersReward += result;
	}

	/// @notice add account to exclusion list no holder to list
	/// @param _account customer address
	function addNoHolder(address _account) public {
		require(!noHolders[_account], "Already Holder");
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

		if (!existDataSnapshot(actualWeek)) {
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
					if (!existDataSnapshot(i)) {
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
			if (!existDataSnapshot(i)) {
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
			if (!existDataSnapshot(i)) {
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