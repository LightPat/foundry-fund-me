// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// Custom Errors save gas
error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // Minimum funding amount expressed in USD, scaled to 18 decimals
    // We use 18 decimals to match ETH's wei precision for easy comparison
    // Constant keyword saves gas
    uint256 public constant MINIMUM_USD = 5e18;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    // Immutable keyword saves gas
    address public immutable I_OWNER;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        I_OWNER = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // msg.value is the amount of ETH sent, denominated in wei
        // 1 ETH = 1e18 wei

        // Convert the sent ETH amount into its USD value
        // and ensure it is at least $5.00 (5e18 in scaled USD)
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough ETH");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;

        }
        s_funders = new address[](0);

        // withdraw the funds
        // https://solidity-by-example.org/sending-ether/

        // transfer (2300 gas, throws error)
        // msg.sender is of type address, so cast to payable type
        // payable(msg.sender).transfer(address(this).balance);

        // send (2300 gas, returns bool)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call (forward all gas or set gas, returns bool)
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        // require(msg.sender == I_OWNER, FundMe__NotOwner());
        if (msg.sender != I_OWNER) { revert FundMe__NotOwner(); }
    }

    // If msg.data is empty, receive will be called
    receive() external payable {
        fund();
    }

    // If msg.data isn't empty but it doesn't match any other function in our contract, fallback will be called
    fallback() external payable {
        fund();
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    /**
     * View / Pure Functions (Getters)
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }
}