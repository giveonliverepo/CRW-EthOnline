// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// any specific tokenomics? max supply? only certain restaurants can mint?
// what kind of validation do we need to put on the verify function? restaurants can't assign to themselves; whitelist to who the token can be sent
// should the mint only be called internally from the verify function

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CRWCP is ERC20, Ownable, AccessControl {
    bytes32 public constant RESTAURANT = keccak256("RESTAURANT");
    // percentage of the total sale amount to be converted in the token. It is as set as a constant. If we want to have the ability to change it, then no constant and a new function should be created for changing this
    uint16 public constant percentage = 5;

    constructor() ERC20("CRW CP", "CRW CP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RESTAURANT, msg.sender);
    }

    // if we call the mint function only through verify, then we don't need this function
    /// @dev minting CRW CP tokens
    function mint(address to, uint256 amount) public onlyRole(RESTAURANT) {
        _mint(to, amount);
    }

    /// @dev adding restaurants that can call the verify functions
    function addRestaurant(address _newRestaurant)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(RESTAURANT, _newRestaurant);
    }

    /// @dev verifying customers' sale and transferring the CRW CP token to the customer in proportion to the sale
    function verify(address _to, uint256 _amount) public onlyRole(RESTAURANT) {
        uint256 tokenTransfer = (_amount * percentage) / 100;
        mint(_to, tokenTransfer);
    }
}
