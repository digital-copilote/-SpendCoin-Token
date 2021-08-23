// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.4;

import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "./DCSnapshot.sol";

/// @title Contract for SpendCoin
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra
/// @notice Main token : SpendCoin

contract SPC_Token is DCSnapshot {

	constructor(address _owner) ERC20("SpendCoin", "SPC") {
		//owner = msg.sender;
		_mint(_owner, 80 * 10**6 * 10**18);
	}
}
