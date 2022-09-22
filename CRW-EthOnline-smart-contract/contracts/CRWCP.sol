// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// what kind of validation do we need to put on the verify function? restaurants can't assign to themselves; whitelist to who the token can be sent
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract CRWCP is ERC20, AccessControl {
    AggregatorV3Interface internal priceFeed;
    bytes32 public constant RESTAURANT = keccak256("RESTAURANT");
    uint16 public percentage = 5;
    mapping(address => mapping(address => uint)) reservation;

    event Mint(address indexed receiver, uint256 _amount);

    constructor() ERC20("CRW CP", "CRW CP") {
        // eth/usd
        priceFeed = AggregatorV3Interface(
            0x57241A37733983F97C4Ab06448F244A1E0Ca0ba8
        );
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RESTAURANT, msg.sender);
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/
            int price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function updatePercentage(uint16 _percentage)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        percentage = _percentage;
    }

    /// @dev top-up functionality to buy tokens in exchange of chain native currency
    /// @notice The value of 1 token is equal to 1 dollar. This is calculated by using a price feed matic/usd
    function buyToken(uint256 _amount) public payable {
        int conversionRatio = getLatestPrice() * 1e10;
        require(_amount >= 1 * 1e16, "Minimum is 1 token");
        require(
            msg.value >= _amount / uint256(conversionRatio),
            "Not enough amount"
        );

        (bool sent, ) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Matic");

        _mint(msg.sender, _amount);

        emit Mint(msg.sender, _amount);
    }

    /// @dev adding restaurants that can call the verify functions
    /// @notice users receive 3 tokens for each new restaurant added
    function addRestaurant(address _newRestaurant) public {
        _grantRole(RESTAURANT, _newRestaurant);
        _mint(msg.sender, 3e18);
    }

    /// @dev reserving a restaurant appointment and saving it as an entry
    /// @dev reserving also whitelist the restaurant
    function reserve(address _restaurant, uint256 _timestamp) public {
        reservation[msg.sender][_restaurant] = _timestamp;
        _grantRole(RESTAURANT, _restaurant);
    }

    /// @dev verifying customers' sale and transferring the CRW CP token to the customer in proportion to the sale
    /// @notice the amount must have 16 decimals
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

        emit Mint(_customer, tokenTransfer);
    }

    receive() external payable {}
}
