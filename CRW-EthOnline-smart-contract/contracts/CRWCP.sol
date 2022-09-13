// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// what kind of validation do we need to put on the verify function? restaurants can't assign to themselves; whitelist to who the token can be sent
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CRWCP is ERC20, AccessControl {
    bytes32 public constant RESTAURANT = keccak256("RESTAURANT");
    // percentage of the total sale amount to be converted in the token. It is as set as a constant. If we want to have the ability to change it, then no constant and a new function should be created for changing this
    uint16 public constant percentage = 5;
    mapping(address => mapping(address => uint)) reservation;

    constructor() ERC20("CRW CP", "CRW CP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RESTAURANT, msg.sender);
    }

    /// @dev adding restaurants that can call the verify functions
    function addRestaurant(address _newRestaurant)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(RESTAURANT, _newRestaurant);
    }

    /// @dev reserving a restaurant appointment and saving it as an entry
    function reserve(address _restaurant, uint256 _timestamp) public {
        reservation[msg.sender][_restaurant] = _timestamp;
    }

    /// @dev verifying customers' sale and transferring the CRW CP token to the customer in proportion to the sale
    function verify(address _customer, uint256 _amount)
        public
        onlyRole(RESTAURANT)
    {
        require(
            reservation[_customer][msg.sender] != 0,
            "No reservation exists"
        );
        uint256 tokenTransfer = (_amount * percentage) / 100;
        _mint(_customer, tokenTransfer);
    }
}
