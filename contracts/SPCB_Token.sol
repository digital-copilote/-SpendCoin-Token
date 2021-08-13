// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title contract for SpendCoinBack
/// @author Olivier Fernandez / Mickaël Bouvier / Anis Boussedra
/// @notice create token : SpendCoinBack
/// @notice le contract doit etre appele par le contract gateway jamais en direct

contract SPCB_Token is ERC20, AccessControl {

	address ownerContract;

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public constant DEVELOPPER_ROLE = keccak256("DEVELOPPER_ROLE");

	address contractGatewayAddress;

	event Received(address, uint);

	modifier adminRole() {
		require(hasRole(ADMIN_ROLE, _msgSender()), "You are not admin");
		_;
	}

	modifier developperRole() {
		require(hasRole(DEVELOPPER_ROLE, _msgSender()), "You are not developper");
		_;
	}

	modifier noContractGateway() {
		require(contractGatewayAddress == _msgSender(), "bad Contract Gateway address");
		_;
	}

	constructor() ERC20("SpendCoinBack", "SPCB") {
		ownerContract = msg.sender;
		contractGatewayAddress = address(0);

		/// @dev give admin rights to contract owner to DEVELOPPER_ROLE
		_setupRole(ADMIN_ROLE, ownerContract);
		_setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

		/// @dev by default admin is a DEVELOPPER_ROLE
		_setupRole(DEVELOPPER_ROLE, ownerContract);
		_setRoleAdmin(DEVELOPPER_ROLE, ADMIN_ROLE);
	}

	/// @dev disable all unused functions
	function approve(address spender, uint256 amount) public override returns (bool) {}
	function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {}
	function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {}
	function allowance(address owner, address spender) public view override returns (uint256) {}
	function transfer(address recipient, uint256 amount) public override returns (bool) {
		//require(false,"message");
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {} // TODO : add transfertFrom pour reset un compte ?

	/// @notice burn SpendCashBack
	/// @param _account customer address
	/// @param _burnAmount amount to burn
	function burn(address _account, uint _burnAmount) public /* noContractGateway() */ {
		if(_burnAmount > 0) _burn(_account, _burnAmount);
	}

	/// @notice reward SpendCashBack
	/// @param _account customer address
	/// @param _rewardAmount amount to reward
	function reward(address _account, uint _rewardAmount) public /* noContractGateway() */ {
		if(_rewardAmount > 0) _mint(_account, _rewardAmount);
	}

	/// @notice add developper
	/// @param _account developper address
	function addDevelopper(address _account) public /* adminRole() */ {
		grantRole(DEVELOPPER_ROLE, _account);
	}

	function setContractGatewayAddress(address _contract) public /* developperRole() */ {
		contractGatewayAddress = _contract;
	}

	function getContractGatewayAddress() public view returns(address) {
		return contractGatewayAddress;
	}

	/// @notice auto revert to sender balance
	receive() external payable {
		//_transfer(address(this), _msgSender(), msg.value);
		emit Received(_msgSender(), msg.value);
	}
}
