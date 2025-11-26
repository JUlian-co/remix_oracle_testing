// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
}
interface IMockPrices {
    function getEthUsdPrice() external view returns (uint256);
    function getTokenPrice(uint32 secondsAgo) external view returns (uint256);
}


contract TestnetPrice {
    address public priceSource;
    
    address public constant token = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; 

    constructor(address _priceSource) {
        priceSource = _priceSource;
    }
    
    
    function getTokenDecimals() internal view returns (uint8) {
        return IERC20(token).decimals();
    }
    
    function getEthUsdPrice() public view returns (uint256) {
        return IMockPrices(priceSource).getEthUsdPrice();
    }
    
    function getMockTokenPrice(uint32 secondsAgo) public view returns (uint256) {
        return IMockPrices(priceSource).getTokenPrice(secondsAgo);
    }

    function usdToToken(
        uint256 usdAmount,       // z. B. 900 (für 9.00 USD) -> Skalierung 10^2
        uint32 secondsAgo
    ) 
        public 
        view 
        returns (uint256 tokensNeeded) 
    {
        uint256 tokenEth = getMockTokenPrice(secondsAgo); // ~0.00082 ETH
        uint256 ethUsd = getEthUsdPrice();              // 3000 USD
        
        uint8 tokenDecimals = getTokenDecimals();

        require(tokenEth > 0, "Token/ETH price is zero.");
        require(ethUsd > 0, "ETH/USD price is zero.");
        
        uint256 denominator = tokenEth * ethUsd;

        uint256 tokenDecimalsMultiplier = 10**uint256(tokenDecimals); 
        
        uint256 numeratorPart1 = usdAmount * 1e18; 
        uint256 numeratorPart2 = numeratorPart1 * 1e6;
        uint256 numerator = numeratorPart2 * tokenDecimalsMultiplier;

        tokensNeeded = numerator / denominator;
        
        return tokensNeeded;
    }
}