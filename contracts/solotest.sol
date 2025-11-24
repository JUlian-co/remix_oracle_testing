// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

contract PriceOracle {
    address public constant token = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // PEPE
    address public constant weth = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;  // WETH

    // KORREKTER PEPE/WETH UNISWAP V3 0.3% Pool
    address public constant pool = 0x6Ce0896eAE6D4BD668fDe41BB784548fb8F59b50;

    function getTokenPrice(uint32 secondsAgo) public view returns (uint256) {
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(pool, secondsAgo);

        return OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            1e6, // 1 token (wenn 18 decimals)
            token,
            weth
        );
    }
}
