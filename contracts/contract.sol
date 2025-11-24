 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED
 * VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * If you are reading data feeds on L2 networks, you must
 * check the latest answer from the L2 Sequencer Uptime
 * Feed to ensure that the data is accurate in the event
 * of an L2 sequencer outage. See the
 * https://docs.chain.link/data-feeds/l2-sequencer-feeds
 * page for details.
 */
contract DataConsumerV3 {
  AggregatorV3Interface internal dataFeed;

  /**
   * Network: Sepolia
   * Aggregator: BTC/USD
   * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
   */
  constructor() {
    dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
  }

  /**
   * Returns the latest answer.
   */
  function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
    // prettier-ignore
    (
      /* uint80 roundId */
      ,
      int256 answer,
      /*uint256 startedAt*/
      ,
      /*uint256 updatedAt*/
      ,
      /*uint80 answeredInRound*/
    ) = dataFeed.latestRoundData();
    return answer;
  }

  function getEthUsdPrice() public view returns (uint256) {
        (, int256 answer,,,) = dataFeed.latestRoundData();
        // Preis kommt mit 8 Dezimalstellen, z.B. 3000.00000000
        return uint256(answer);
    }

    // Beispiel: 20 USD → Wie viel ETH?
    function usdToEth(uint256 usdAmount) public view returns (uint256) {
        uint256 ethPrice = getEthUsdPrice(); // in USD * 1e8
        // usdAmount ist in USD, also * 1e18 normalisieren
        uint256 usdInWei = usdAmount * 1e18;

        // ETH = USD / ETH_USD_Preis
        return usdInWei / ethPrice;
    }
}
