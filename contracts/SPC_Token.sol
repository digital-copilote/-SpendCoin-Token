// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/// @title contract for SpendCoin
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra
/// @notice create token : SpendCoin

contract SPC_Token is ERC20 {

    constructor() ERC20("SpendCoin", "SPC") {
        //ownerContract = msg.sender;
		_mint(msg.sender, 80000000 * 10**18);
	}


}
