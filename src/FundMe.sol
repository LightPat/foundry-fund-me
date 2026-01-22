// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

// Custom Errors save gas
error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // Minimum funding amount expressed in USD, scaled to 18 decimals
    // We use 18 decimals to match ETH's wei precision for easy comparison
    // Constant keyword saves gas
    uint256 public constant MINIMUM_USD = 5e18;

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    // Immutable keyword saves gas
    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        // msg.value is the amount of ETH sent, denominated in wei
        // 1 ETH = 1e18 wei

        // Convert the sent ETH amount into its USD value
        // and ensure it is at least $5.00 (5e18 in scaled USD)
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;

        }
        funders = new address[](0);

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
        // require(msg.sender == i_owner, NotOwner());
        if (msg.sender != i_owner) { revert NotOwner(); }
        _;
    }

    // If msg.data is empty, receive will be called
    receive() external payable {
        fund();
    }

    // If msg.data isn't empty but it doesn't match any other function in our contract, fallback will be called
    fallback() external payable {
        fund();
    }
}