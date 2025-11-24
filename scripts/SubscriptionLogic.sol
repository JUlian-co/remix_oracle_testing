// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28; // 28

/* import {BrixSmartWallet} from "../contracts/BrixSmartWallet.sol"; */
import { BrixSmartWalletLogicV1 } from "contracts/BrixSmartWalletLogicV1.sol"; // Interface nutzen anstatt diesen kack importieren

interface IBrixSmartWalletLogicV1 { // IBrixSmartWallet
    function lastPayments(
        address merchant,
        uint256 productId
    ) external view returns (uint256);

    function processPayment(
        address merchant,
        uint256 productId,
        uint256 amount // !! einbauen dass man mit mehrern coins zahlen bzw  implementieren kann, also man hier noch die token addresse eingeben muss mit der user sich entschieden hat zu zahlen !!
    ) external;

    function getAuthorization(
        address merchant,
        uint256 productId
    )
        external
        view
        returns (
            address merchantAddress,
            uint256 amountPerInterval,
            uint256 interval
        );
}

contract BrixSubscriptionLogic {
    event SubscriptionPaymentTriggered(
        IBrixSmartWalletLogicV1 indexed userWallet,
        address indexed merchant,
        uint256 indexed productId
    );
    event ProductCreated(
        uint256 indexed productId,
        address indexed merchant,
        uint256 amountPerInterval,
        uint256 interval,
        string productName
    );

    error BrixSubscriptionLogic__NotAuthorizedAmount();
    error BrixSubscriptionLogic__NotAuthorizedInterval();
    error BrixSubscriptionLogic__InvalidInterval();

    uint256 constant DAILY = 86400;
    uint256 constant WEEKLY = 604800;
    uint256 constant MONTHLY = 2592000;
    uint256 constant QUARTERLY = 7862400;
    uint256 constant YEARLY = 31536000;

    struct Product {
        uint256 productId;
        address merchant;
        uint256 amountPerInterval;
        uint256 interval;
        string productName;
        address currency; // NEU
    }

    mapping(address => uint256) public nextProductIdOfMerchant;
    mapping(address => mapping(uint256 => Product)) public productOf;

    function createProduct(
        uint256 amountPerInterval,
        uint256 interval,
        string calldata productName,
        address currency // NEU
    ) external {
        if (interval != DAILY && interval != WEEKLY && interval != MONTHLY && interval != QUARTERLY && interval != YEARLY) {
            revert BrixSubscriptionLogic__InvalidInterval();
        }
        
        address merchant = msg.sender; // TODO: Change that
        uint256 currentProductId = nextProductIdOfMerchant[merchant];
        productOf[merchant][currentProductId] = Product({
            productId: currentProductId,
            merchant: merchant, 
            amountPerInterval: amountPerInterval,
            interval: interval,
            productName: productName,
            currency: currency
        });
        nextProductIdOfMerchant[merchant]++;
        emit ProductCreated(
            currentProductId,
            merchant,
            amountPerInterval,
            interval,
            productName
        );
    }

    function isPaymentDue(
        address _userWallet,
        address merchant,
        uint256 productId
    ) public view returns (bool) {
        IBrixSmartWalletLogicV1 userWallet = IBrixSmartWalletLogicV1(_userWallet);
        uint256 lastPayment = userWallet.lastPayments(merchant, productId);
        uint256 interval = productOf[merchant][productId].interval;
        return (block.timestamp >= lastPayment + interval);
    }

    function triggerPayment(
        address _userWallet,
        address merchant,
        uint256 productId
    ) external {
        IBrixSmartWalletLogicV1 userWallet = IBrixSmartWalletLogicV1(_userWallet);
        uint256 amount = productOf[merchant][productId].amountPerInterval;
        uint256 interval = productOf[merchant][productId].interval;
        (, uint256 authorizedAmount, uint256 authorizedInterval) = userWallet
            .getAuthorization(merchant, productId);
        // require(authorizedAmount == amount, "Not authorized for this amount");
        if (authorizedAmount != amount) {
            revert BrixSubscriptionLogic__NotAuthorizedAmount();
        }
        if (authorizedInterval != interval) {
            revert BrixSubscriptionLogic__NotAuthorizedInterval();
        }

        userWallet.processPayment(merchant, productId, amount);

        emit SubscriptionPaymentTriggered(userWallet, merchant, productId);
    }

    function getProductsOf(address merchant) external view returns (Product[] memory) {
        uint256 productCount = nextProductIdOfMerchant[merchant];
        Product[] memory products = new Product[](productCount);
        
        for (uint256 i = 0; i < productCount; i++) {
            products[i] = productOf[merchant][i];
        }
        
        return products;
    }

    function getActiveSubscription(
        address _userWallet,
        address merchant,
        uint256 productId
    )
        external
        view
        returns (
            bool isAuthorized,
            uint256 lastPayment,
            uint256 interval,
            uint256 amountPerInterval
        )
    {
        IBrixSmartWalletLogicV1 userWallet = IBrixSmartWalletLogicV1(_userWallet);
        (
            address authorizedMerchat,
            uint256 authorizedAmount,
            uint256 authorizedInterval
        ) = userWallet.getAuthorization(merchant, productId);

        // isAuthorized = (authorizedAmount != 0); // Wenn Amount != 0, existiert die Authorization
        isAuthorized = (authorizedMerchat != address(0)); // Wenn Merchant != 0, existiert die Authorization
        lastPayment = userWallet.lastPayments(merchant, productId);
        interval = authorizedInterval;
        amountPerInterval = authorizedAmount;
    }
}
