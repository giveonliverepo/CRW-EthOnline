// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// what kind of validation do we need to put on the verify function? restaurants can't assign to themselves; whitelist to who the token can be sent
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

/**
 * @title CRW-CP contract
 * @author Alessandro Maci
 * @notice Not all functions have been tested
 **/

contract CRWCP is ERC20, AccessControl {
    // ========================================================
    // Storage
    // ========================================================
    AggregatorV3Interface internal priceFeed;

    // mumbai aave pool 0x6C9fB0D5bD9429eb9Cd96B85B81d872281771E6B
    // optimism aave pool 0x4b529A5d8268d74B687aC3dbb00e1b85bF4BF0d4
    IPool public AAVE_POOL = IPool(0x6C9fB0D5bD9429eb9Cd96B85B81d872281771E6B);

    // mumbai usdc 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747
    // optimism usdc 0x7F5c764cBc14f9669B88837ca1490cCa17c31607
    IERC20 public USDC = IERC20(0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747);

    bytes32 public constant RESTAURANT = keccak256("RESTAURANT");

    uint16 public percentage = 5;

    // ========================================================
    // Mappings
    // ========================================================
    mapping(address => mapping(address => uint)) reservation;
    mapping(address => uint256) tokenStaked;

    // ========================================================
    // Events
    // ========================================================
    event Mint(address indexed receiver, uint256 _amount);
    event Burn(address indexed receiver, uint256 _amount);

    // ========================================================
    // Util Methods
    // ========================================================
    constructor() ERC20("CRW CP", "CRW CP") {
        // eth/usd optimism 0x57241A37733983F97C4Ab06448F244A1E0Ca0ba8
        // matic/usd mumbai 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
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

    // ========================================================
    // Main Methods
    // ========================================================

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
    /// @notice reserving also whitelist the restaurant
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

    /// @dev using CRWCP token to supply liquidity in AAVE
    function supplyLiquidity(uint256 _amount) public {
        uint256 usdc = _amount / 1e12;
        require(USDC.balanceOf(address(this)) > usdc, "Insufficient funds");

        AAVE_POOL.supply(address(USDC), usdc, address(this), 0);

        tokenStaked[msg.sender] = _amount;
        _burn(msg.sender, _amount);

        emit Burn(msg.sender, _amount);
    }

    /// @dev closing the AAVE deposit position and the equivalent amount of CRWCP is transferred back to users
    function withdrawLiquidity() public {
        require(tokenStaked[msg.sender] > 0, "There is nothing staked");

        uint256 usdc = AAVE_POOL.withdraw(
            address(USDC),
            tokenStaked[msg.sender],
            address(this)
        );

        tokenStaked[msg.sender] = 0;

        uint256 crw_cp = usdc * 1e12;
        _mint(msg.sender, crw_cp);

        emit Mint(msg.sender, crw_cp);
    }

    receive() external payable {}
}
