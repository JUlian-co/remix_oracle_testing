// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";


interface IERC20 {
    function decimals() external view returns (uint8);
}

interface IContract {
    function getEthUsdPrice() external view returns (uint256);
}

contract PriceOracle {
    address public constant token = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // PEPE
    address public constant weth = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;  // WETH

    // KORREKTER PEPE/WETH UNISWAP V3 0.3% Pool
    /* address public constant pool = 0x6Ce0896eAE6D4BD668fDe41BB784548fb8F59b50; */

    function getTokenPrice(uint32 secondsAgo) public view returns (uint256) {
        address pool = getPoolAddress();
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(pool, secondsAgo);

        uint8 decimals = IERC20(token).decimals();
        uint128 scale;
        if (decimals == 6) {
            scale = 1e6;
        } else if (decimals == 8) {
            scale = 1e8;
        } else if (decimals == 18) {
            scale = 1e18;
        } else {
            revert("not available interval"); /* TODO: das hier in einen anderen contract machen dass wir es updaten können */
        }

        return OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            scale,
            token,
            weth
        );
    }


    function getPoolAddress() internal  pure returns (address) {
        PoolAddress.PoolKey memory key = PoolAddress.PoolKey({
            token0: token,
            token1: weth,
            fee: 3000
        });

        address poolAddress = PoolAddress.computeAddress(
            0x0227628f3F023bb0B980b67D528571c95c6DaC1c,
            key
        );

        return poolAddress;
    }

    function usdToToken(
        uint256 usdAmount,        // z. B. 900 → 9.00 USD
        uint32 secondsAgo        // z. B. 120
    ) 
        public 
        view 
        returns (uint256) 
    {
        // 1) Token → ETH price (wei)
        uint256 tokenEth = getTokenPrice(secondsAgo);

        // 2) ETH → USD price (1e8)
        uint256 ethUsd = IContract(0xf623109f16Fdf8ef1dA0830c5B1c7ba9dBa4A06E).getEthUsdPrice(); // Chainlink aggregator

        uint256 tokenUsd = tokenEth * ethUsd;

        return usdAmount / tokenUsd; /* NOT DONE YET!!!!!!!!!!!!!!!!!!! */
    }

}
