// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Das Mock-Orakel für den ETH-Preis
contract MockPrices {
    // Statischer Preis: 3000 USD, skaliert auf 10^8 Dezimalstellen
    uint256 public constant MOCK_ETH_USD_PRICE = 300000000000;
    uint256 public constant MOCK_TOKEN_ETH_PRICE = 820000000000000; // ~0.00082 ETH

    function getEthUsdPrice() external pure returns (uint256) {
        return MOCK_ETH_USD_PRICE;
    }

    // Simuliert die Schnittstelle Ihrer getTokenPrice Funktion
    function getTokenPrice(uint32 secondsAgo) public pure returns (uint256) {
        // secondsAgo wird ignoriert
        return MOCK_TOKEN_ETH_PRICE; 
    }
}