// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/// @title Contract for SpendCoin
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra
/// @notice Main token : SpendCoin

contract SPC_Token is ERC20Snapshot {

    constructor() ERC20("SpendCoin", "SPC") {
        //ownerContract = msg.sender;
		_mint(msg.sender, 80000000 * 10**18);
	}

    function snapshot() public returns (uint256) {
        // TODO
        // verif si semaine a change, increment semaine si necessaire
        //require();
        // verif appelant
        // require(msg.sender == );
		return _snapshot(); // TODO: return bool / uint ?
	}

    function getCurrentSnapshotId() public view returns (uint256) {
		return _getCurrentSnapshotId();
    }
}
