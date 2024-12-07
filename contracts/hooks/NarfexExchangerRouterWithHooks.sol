// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

interface INarfexFiat is IERC20 {
    function burnFrom(address _address, uint _amount) external;
    function mintTo(address _address, uint _amount) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

/// @title Exchange Router with Uniswap V4 Hooks for Narfex
/// @notice Facilitates fiat and crypto exchanges via Uniswap V4
contract NarfexExchangerRouterWithHooks is Ownable, IHooks {
    using SafeERC20 for IERC20;

    IPoolManager public poolManager;
    IWETH public WETH;
    IERC20 public USDC;

    uint constant PRECISION = 10**18;
    uint constant PERCENT_PRECISION = 10**4;

    struct TokenData {
        bool isFiat;
        uint price; // USD price in 18 decimals
        uint transferFee; // Fee in 1/10000th precision (100 = 1%)
    }

    mapping(address => TokenData) public tokens;

    event BeforeSwap(address indexed sender, IPoolManager.PoolKey key, uint amountSpecified);
    event AfterSwap(address indexed sender, IPoolManager.PoolKey key, uint amountOut);
    event TokenUpdated(address indexed token, bool isFiat, uint price, uint transferFee);

    constructor(
        address _poolManager,
        address _weth,
        address _usdc
    ) {
        poolManager = IPoolManager(_poolManager);
        WETH = IWETH(_weth);
        USDC = IERC20(_usdc);
    }

    /// @notice Updates token metadata
    /// @param token Address of the token
    /// @param isFiat Boolean indicating if the token is fiat
    /// @param price Price of the token in USD (18 decimals)
    /// @param transferFee Transfer fee for the token in basis points
    function updateToken(address token, bool isFiat, uint price, uint transferFee) external onlyOwner {
        tokens[token] = TokenData({isFiat: isFiat, price: price, transferFee: transferFee});
        emit TokenUpdated(token, isFiat, price, transferFee);
    }

    /// @notice Hook logic for `beforeSwap`
    function beforeSwap(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params,
        bytes calldata
    ) external override returns (bytes4) {
        require(tokens[key.token0].isFiat || tokens[key.token1].isFiat, "No fiat tokens involved");
        emit BeforeSwap(sender, key, params.amountSpecified);
        return IHooks.beforeSwap.selector;
    }

    /// @notice Hook logic for `afterSwap`
    function afterSwap(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params,
        IPoolManager.BalanceDelta memory swapDelta,
        bytes calldata
    ) external override {
        require(tokens[key.token0].isFiat || tokens[key.token1].isFiat, "No fiat tokens involved");
        emit AfterSwap(sender, key, uint256(swapDelta.amountOut));
    }

    /// @notice Hook logic for `beforeInitialize` (optional)
    function beforeInitialize(
        address sender,
        IPoolManager.PoolKey memory key,
        uint160 sqrtPriceX96,
        bytes calldata
    ) external override returns (bytes4) {
        return IHooks.beforeInitialize.selector;
    }

    /// @notice Hook logic for `afterInitialize` (optional)
    function afterInitialize(
        address sender,
        IPoolManager.PoolKey memory key,
        uint160 sqrtPriceX96,
        bytes calldata
    ) external override {
        // Optional implementation
    }

    /// @notice Executes a token swap using Uniswap V4 pools
    /// @param key Pool key specifying the tokens in the pair
    /// @param params Swap parameters
    /// @param deadline Expiry time for the transaction
    function executeSwap(
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params,
        uint deadline
    ) external payable {
        require(deadline >= block.timestamp, "Transaction expired");

        // Approve the pool for WETH or USDC as needed
        if (key.token0 == address(WETH) || key.token1 == address(WETH)) {
            WETH.deposit{value: msg.value}();
        }

        // Execute the swap
        poolManager.swap(key, params);
    }

    /// @notice Handles ETH deposits for WETH conversion
    receive() external payable {
        require(msg.sender == address(WETH), "Direct deposits not allowed");
    }

    /// @notice Withdraw WETH as ETH
    /// @param amount Amount of WETH to withdraw
    function withdrawWETH(uint amount) external onlyOwner {
        WETH.withdraw(amount);
        payable(owner()).transfer(amount);
    }
}
