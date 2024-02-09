// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// Contract to facilitate donations for crowdfunding.
contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded; // mapped amount sent to its sender.
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        // ensure owner is the contract deployer.
        owner = msg.sender;
    }

    // func to enable sending.
    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18;
        // Ensure no broke mf can call this func ($50).
        require(getConversionRate(msg.value) >= minimumUSD, "More ETH!!!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); // all senders to a list.
    }

    // func to get the latest version of the aggregator interface being used.
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // func to get current eth/usd price.
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // answer in wei.
    }

    // func to get USD equivalent of any eth amount.
    function getConversionRate(
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        // 2251.360827220000000000
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    // modifies the withdraw func in a declarative way (i.e checks owner before running)
    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    // func to withdraw funds.
    function withdraw() public payable onlyowner {
        msg.sender.transfer(address(this).balance);

        // reset all senders balance to 0 on withdrawal.
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // reset the senders array.
    }
}
