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
    address public constant token = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
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

    function getTokensForUSD(
        uint256 usdAmount_6Decimals, // z.B. 100 * 1e6
        uint256 ethPriceInUSD_8Decimals, // Preis von Chainlink
        uint256 tokenPriceInETH_18Decimals, // Ihr berechneter Preis P_token_eth
        uint8 tokenDecimals // D_token
    ) public pure returns (uint256 tokensNeeded) {
        // **********************************************
        // 1. Berechnung des Korrekturfaktors (10^(24 + D_token))
        // **********************************************
        // 6 (usdAmount) + 18 (für tokenPriceInETH-Skalierung) + D_token (für End-Skalierung)
        // Wir multiplizieren nur mit 10^6, da die anderen Faktoren (10^18) und (10^D_token) dynamisch hinzugefügt werden.
        // 24 - 8 (ethPrice) = 16.
        
        // Einfache Variante (direkt aus der Formel):
        // Denken Sie an die Skalierung: 
        // Zähler: 10^6 * 10^D_token * 10^18  -> total 10^(24 + D_token)
        // Nenner: 10^18 * 10^8 -> total 10^26
        
        // M_token = (usdAmount_6Decimals * 10^D_token * 10^18) / (tokenPriceInETH_18Decimals * ethPriceInUSD_8Decimals)
        
        // Die 10^18 und 10^D_token müssen wir in der Multiplikation hinzufügen, 
        // damit das Ergebnis in der richtigen Dezimalstellen-Skalierung ist.

        uint256 multiplier = 1e18; // 10^18 aus P_token_eth (Nenner wird 10^18 * 10^8 = 10^26)
        
        // Fügen wir die tokenDecimals Skalierung hinzu, um M_token auf 10^D_token zu bringen.
        // M_token = (M_usd * 10^D_token * 10^18) / (P_token_eth * P_eth_usd)
        
        // tokenDecimals (10^D_token)
        uint256 tokenDecimalsMultiplier = 1;
        if (tokenDecimals > 0) {
            tokenDecimalsMultiplier = 10**tokenDecimals;
        }

        // ACHTUNG: Die Gesamt-Skalierung wird sehr groß!
        // Wir müssen die 10^6 und 10^D_token so unterbringen, dass das Endergebnis richtig skaliert ist.

        // Besser ist, die Formel von Schritt 2 zu verwenden:
        // M_token = (M_usd (6) * S_token (D_token)) / (P_token_usd (8)) 
        // und P_token_usd ist (P_token_eth (18) * P_eth_usd (8)) / 10^18 (Normalisierung)

        // 1. Preis in USD (skaliert auf 8 Dezimalstellen)
        // Skalierung: (10^18 * 10^8) / 10^18 = 10^8
        uint256 tokenPriceInUSD_8Decimals = (tokenPriceInETH_18Decimals * ethPriceInUSD_8Decimals) / 1e18;
        
        // Überprüfen, ob der Preis Null ist, um Division durch Null zu vermeiden
        require(tokenPriceInUSD_8Decimals > 0, "Price must be greater than zero");

        // 2. Benötigte Token-Menge
        // Formel: M_token (D_token) = (M_usd (6) * 10^D_token) / P_token_usd (8)
        // Skalierung: (10^6 * 10^D_token) / 10^8 = 10^(D_token - 2)
        // Da wir aber M_token auf 10^D_token haben wollen, müssen wir mit 10^2 multiplizieren.
        // Das heißt, wir müssen den Zähler mit 10^2 erweitern.

        // M_token = (usdAmount_6Decimals * tokenDecimalsMultiplier * 1e2) / tokenPriceInUSD_8Decimals
        // Zähler: 10^6 * 10^D_token * 10^2 = 10^(8 + D_token)
        // Nenner: 10^8
        // Ergebnis: 10^D_token (korrekt skaliert)

        uint256 numerator = usdAmount_6Decimals * tokenDecimalsMultiplier * 100; // * 1e2
        
        return numerator / tokenPriceInUSD_8Decimals;
    }


        function anotherUsdToToken(
            uint256 usdAmount,       // z. B. 900 (für 9.00 USD) -> Skalierung 10^2
            uint32 secondsAgo,
            uint8 tokenDecimals     // Zwingend erforderlich, z.B. 18
        ) 
            public 
            view 
            returns (uint256 tokensNeeded) 
        {
            // 1) Token → ETH price (wei)
            // Skalierung: 10^18
            uint256 tokenEth = getTokenPrice(secondsAgo); 

            // 2) ETH → USD price (1e8)
            // Skalierung: 10^8
            uint256 ethUsd = IContract(0xf623109f16Fdf8ef1dA0830c5B1c7ba9dBa4A06E).getEthUsdPrice(); // Chainlink aggregator

            // Sicherstellen, dass die Preise nicht Null sind
            require(tokenEth > 0, "Token/ETH price is zero.");
            require(ethUsd > 0, "ETH/USD price is zero.");
            
            // 1. Nenner (P_token_eth * P_eth_usd) - Skalierung 10^26
            uint256 denominator = tokenEth * ethUsd;
            require(denominator > 0, "Price denominator is zero.");

            // 2. Zähler: M_usd * Korrekturfaktor (10^24 * 10^D_token)
            uint256 tokenDecimalsMultiplier = 10**tokenDecimals;

            // A. Multipliziere mit 10^18 (für tokenEth-Skalierung)
            uint256 numeratorPart1 = usdAmount * 1e18; 
            
            // B. Multipliziere mit 10^6 (Ausgleich für ethUsd-Skalierung 10^8 minus usdAmount-Skalierung 10^2)
            uint256 numeratorPart2 = numeratorPart1 * 1e6;
            
            // C. Multipliziere mit 10^D_token (Ergebnis auf Zielskalierung bringen)
            uint256 numerator = numeratorPart2 * tokenDecimalsMultiplier;

            tokensNeeded = numerator / denominator;
            
            return tokensNeeded;
        }

}
