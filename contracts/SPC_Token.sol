// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/// @title Contract for SpendCoin
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra
/// @notice Main token : SpendCoin

contract SPC_Token is ERC20Snapshot {

	uint lastSnapshotTimestamp = block.timestamp;
	uint delay = 1 weeks;

	constructor(address _owner) ERC20("SpendCoin", "SPC") {
		//owner = msg.sender;
		_mint(_owner, 80 * 10**6 * 10**18);
	}

	function snapshot() public returns (uint256) { // returns (bool, uint256)
		// TODO
		// verif si semaine a change, increment semaine si necessaire
		require(block.timestamp >= lastSnapshotTimestamp + delay, "Semaine non terminee");
		// verif appelant? => pas besoin
		// require(msg.sender == owner);
		lastSnapshotTimestamp = block.timestamp;
		return _snapshot(); // TODO: return bool / uint ? => returns (bool, uint256)
	}

	function getCurrentSnapshotId() public view returns (uint256) {
		return _getCurrentSnapshotId();
	}
}
