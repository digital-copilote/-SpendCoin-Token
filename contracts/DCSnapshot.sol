// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Contract for Snapshot on SpendCoin
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra

abstract contract DCSnapshot is ERC20 {

	struct AccountsSnapshots {
		bool exist;
		uint256 balance;
		uint256 minValue;
	}

	uint time20210802 = 1627855200; // lundi 2 août 2021 00:00:00 GMT+02:00

	mapping(uint => mapping (address => AccountsSnapshots)) private _mapWeeks; // weekNumber => account => AccountsSnapshots
	mapping(uint => bool) private _existSnapshop; // weekNumber => exist

	event Snapshot(uint256 id);

	/// @notice calc week number from 01/08/2021
	function calcWeekNumber() private view  returns (uint256) {
		uint date = block.timestamp - time20210802;
		return date /  (7 * 24 * 3600); // week len: 7 * 24 * 60 *60
	}

	/// @notice check if a snapshot exist with this id
	function existSnapshop(uint256 _snapshotId) public view returns (bool) {
		return _existSnapshop[_snapshotId];
	}

	function newSnapshot() public returns (uint256) {
		uint256 newId = calcWeekNumber();
		if (!existSnapshop(newId)) {
			_existSnapshop[newId] = true;
			emit Snapshot(newId);
		}
		return newId;
	}

	function balanceOfAt(address _account, uint256 _snapshotId) public view returns (bool, uint256) {
		if (!existSnapshop(_snapshotId) || !_mapWeeks[_snapshotId][_account].exist) {
			return (false, 0);
		} else {
			return (true, _mapWeeks[_snapshotId][_account].balance);
		}
	}

	function minValueOfAt(address _account, uint256 _snapshotId) public view returns (bool, uint256) {
		if (!existSnapshop(_snapshotId) || !_mapWeeks[_snapshotId][_account].exist) {
			return (false, 0);
		} else {
			return (true, _mapWeeks[_snapshotId][_account].minValue);
		}
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override {
		// transfer only, no update on burn and mint
		if (from != address(0) && to != address(0)) { 
			_updateSnapshot(from, balanceOf(from) - amount);
			_updateSnapshot(to, balanceOf(to));
		}
	}

	function _updateSnapshot(address _account, uint256 _currentValue) private {
		uint256 currentId = calcWeekNumber();
		
		if (!existSnapshop(currentId)) {
			currentId = newSnapshot();
		}

		if (!_mapWeeks[currentId][_account].exist) {
			_mapWeeks[currentId][_account].exist = true;
			_mapWeeks[currentId][_account].balance = balanceOf(_account);
			_mapWeeks[currentId][_account].minValue = balanceOf(_account);
		}
		// update values
		if (_mapWeeks[currentId][_account].minValue > _currentValue)
			_mapWeeks[currentId][_account].minValue = _currentValue;
	}
}