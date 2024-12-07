// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/INarfexP2pFactory.sol";
import "../interfaces/INarfexP2pRouter.sol";
import "../hooks/FiatFactoryHook.sol";
import "../hooks/P2PFactoryHook.sol";
import "../hooks/OracleHook.sol";
import "../hooks/ArbitrationHook.sol";


/// @title Narfex P2P Service
/// @notice Handles P2P trading logic, integrating with factories, routers, and hooks
/// @author Narfex
contract P2PService is Ownable {
    using Address for address;

    INarfexP2pFactory public factory;
    INarfexP2pRouter public router;

    mapping(address => bool) private supportedFiatTokens;

    event FiatTokenAdded(address indexed token);
    event FiatTokenRemoved(address indexed token);
    event TradeCreated(address indexed buyer, address indexed seller, uint amount, bytes32 tradeId);
    event TradeCancelled(address indexed buyer, address indexed seller, bytes32 tradeId);
    event TradeConfirmed(address indexed buyer, address indexed seller, bytes32 tradeId);

    struct Trade {
        address buyer;
        address seller;
        uint amount;
        uint price;
        uint status; // 0 = created, 1 = confirmed, 2 = cancelled
        bytes32 tradeId;
        address fiatToken;
    }

    mapping(bytes32 => Trade) public trades;

    constructor(address _factory, address _router) {
        factory = INarfexP2pFactory(_factory);
        router = INarfexP2pRouter(_router);
    }

    modifier onlyKYCVerified(address user) {
        require(factory.isKYCVerified(user), "P2PService: KYC verification required");
        _;
    }

    modifier onlyActiveTrade(bytes32 tradeId) {
        require(trades[tradeId].status == 0, "P2PService: Trade is not active");
        _;
    }

    /// @notice Adds a fiat token to the supported list
    /// @param token Fiat token address
    function addFiatToken(address token) external onlyOwner {
        supportedFiatTokens[token] = true;
        emit FiatTokenAdded(token);
    }

    /// @notice Removes a fiat token from the supported list
    /// @param token Fiat token address
    function removeFiatToken(address token) external onlyOwner {
        supportedFiatTokens[token] = false;
        emit FiatTokenRemoved(token);
    }

    /// @notice Checks if a fiat token is supported
    /// @param token Fiat token address
    /// @return True if supported
    function isSupportedFiatToken(address token) public view returns (bool) {
        return supportedFiatTokens[token];
    }

    /// @notice Creates a new trade
    /// @param buyer Buyer's address
    /// @param seller Seller's address
    /// @param amount Amount of fiat involved
    /// @param price Price in crypto or fiat
    /// @param fiatToken Address of the fiat token
    function createTrade(
        address buyer,
        address seller,
        uint amount,
        uint price,
        address fiatToken
    ) external onlyKYCVerified(buyer) onlyKYCVerified(seller) {
        require(isSupportedFiatToken(fiatToken), "P2PService: Unsupported fiat token");

        bytes32 tradeId = keccak256(
            abi.encodePacked(block.timestamp, buyer, seller, amount, price, fiatToken)
        );

        trades[tradeId] = Trade({
            buyer: buyer,
            seller: seller,
            amount: amount,
            price: price,
            status: 0,
            tradeId: tradeId,
            fiatToken: fiatToken
        });

        emit TradeCreated(buyer, seller, amount, tradeId);
    }

    /// @notice Confirms a trade
    /// @param tradeId Trade identifier
    function confirmTrade(bytes32 tradeId) external onlyActiveTrade(tradeId) {
        Trade storage trade = trades[tradeId];
        require(msg.sender == trade.buyer || msg.sender == trade.seller, "P2PService: Unauthorized");

        trade.status = 1;

        // Execute the fiat token transfer
        IERC20(trade.fiatToken).transferFrom(trade.buyer, trade.seller, trade.amount);

        emit TradeConfirmed(trade.buyer, trade.seller, tradeId);
    }

    /// @notice Cancels a trade
    /// @param tradeId Trade identifier
    function cancelTrade(bytes32 tradeId) external onlyActiveTrade(tradeId) {
        Trade storage trade = trades[tradeId];
        require(msg.sender == trade.buyer || msg.sender == trade.seller, "P2PService: Unauthorized");

        trade.status = 2;

        emit TradeCancelled(trade.buyer, trade.seller, tradeId);
    }

    /// @notice Returns trade details
    /// @param tradeId Trade identifier
    /// @return Trade details
    function getTrade(bytes32 tradeId) external view returns (Trade memory) {
        return trades[tradeId];
    }
}
