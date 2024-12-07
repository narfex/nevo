// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

/// @title Fiat Factory Hook for Narfex
/// @notice Manages fiat token creation and integrates with Uniswap V4 hooks
contract FiatFactoryHook is Ownable, IHooks {
    using Address for address;

    /// Router address to provide access to tokens for a third-party contract
    address private _router;
    /// Mapping TokenSymbol=>Address
    mapping(string => address) public fiats;
    /// All created fiats
    address[] public fiatsList;

    /// Events
    event SetRouter(address router);
    event CreateFiat(string tokenName, string tokenSymbol, address tokenAddress);
    event BeforeSwap(address indexed sender, address indexed token0, address indexed token1, uint256 amountIn);
    event AfterSwap(address indexed sender, address indexed token0, address indexed token1, uint256 amountOut);

    /// @notice Modifier to restrict actions to router or owner
    modifier fullAccess() {
        require(isHaveFullAccess(msg.sender), "Access denied");
        _;
    }

    /// @notice Returns the router address
    /// @return Router address
    function getRouter() public view returns (address) {
        return _router;
    }

    /// @notice Sets the router address
    /// @param router Router address
    function setRouter(address router) public onlyOwner {
        _router = router;
        emit SetRouter(router);
    }

    /// @notice Check if an account has full access
    /// @param account Address to check
    /// @return Boolean indicating access
    function isHaveFullAccess(address account) internal view returns (bool) {
        return account == owner() || account == getRouter();
    }

    /// @notice Creates a new fiat token
    /// @param tokenName Name of the token
    /// @param tokenSymbol Symbol of the token
    function createFiat(string memory tokenName, string memory tokenSymbol) public fullAccess {
        address newFiat = address(new FiatToken(tokenName, tokenSymbol, address(this)));
        fiats[tokenSymbol] = newFiat;
        fiatsList.push(newFiat);
        emit CreateFiat(tokenName, tokenSymbol, newFiat);
    }

    /// @notice Returns the number of created fiats
    /// @return Number of tokens
    function getFiatsQuantity() public view returns (uint) {
        return fiatsList.length;
    }

    /// @notice Returns all fiat token addresses
    /// @return Array of fiat token addresses
    function getFiats() public view returns (address[] memory) {
        return fiatsList;
    }

    /// @notice Hook called before a swap
    function beforeSwap(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params,
        bytes calldata hookData
    ) external override returns (bytes4) {
        require(fiats[key.token0] != address(0) || fiats[key.token1] != address(0), "No fiat tokens involved");
        emit BeforeSwap(sender, key.token0, key.token1, params.amountSpecified);
        return IHooks.beforeSwap.selector;
    }

    /// @notice Hook called after a swap
    function afterSwap(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params,
        IPoolManager.BalanceDelta memory swapDelta,
        bytes calldata hookData
    ) external override {
        require(fiats[key.token0] != address(0) || fiats[key.token1] != address(0), "No fiat tokens involved");
        emit AfterSwap(sender, key.token0, key.token1, uint256(swapDelta.amountOut));
    }

    /// @notice Hook called before pool initialization
    function beforeInitialize(
        address sender,
        IPoolManager.PoolKey memory key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) external override returns (bytes4) {
        return IHooks.beforeInitialize.selector; // Optional implementation
    }

    /// @notice Hook called after pool initialization
    function afterInitialize(
        address sender,
        IPoolManager.PoolKey memory key,
        uint160 sqrtPriceX96,
        bytes calldata hookData
    ) external override {
        // Optional implementation
    }
}

/// @title Fiat Token
/// @notice ERC20-compatible fiat token for Narfex
contract FiatToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public factory;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, address _factory) {
        name = _name;
        symbol = _symbol;
        factory = _factory;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Not factory");
        _;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) public onlyFactory {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function burn(address from, uint256 value) public onlyFactory {
        require(balanceOf[from] >= value, "Insufficient balance");
        totalSupply -= value;
        balanceOf[from] -= value;
        emit Transfer(from, address(0), value);
    }
}
