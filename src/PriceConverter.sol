// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // Create a price feed instance for ETH / USD
        // This address is the Chainlink ETH-USD feed on Sepolia
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // latestRoundData returns the price with 8 decimals
        // Example:
        // ETH price = 2000.00000000 USD
        // Returned value = 200000000000 (2000 * 10^8)
        (, int256 price,,,) = priceFeed.latestRoundData();

        // Convert price from 8 decimals to 18 decimals
        // 10^18 / 10^8 = 10^10
        //
        // Example:
        // 2000 * 1e8  -> Chainlink output
        // 2000 * 1e18 -> What we want for consistent math
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // ethPrice is ETH/USD with 18 decimals
        // Example: 2000 USD = 2000 * 1e18
        uint256 ethPrice = getPrice(priceFeed);

        // ethAmount is in wei (1 ETH = 1e18 wei)

        // Formula:
        // (ETH price in USD * ETH amount in wei) / 1e18

        // The division by 1e18 cancels out wei,
        // leaving us with USD scaled to 18 decimals

        // Example:
        // ethPrice = 2000e18
        // ethAmount = 1e18 (1 ETH)

        // (2000e18 * 1e18) / 1e18 = 2000e18
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
