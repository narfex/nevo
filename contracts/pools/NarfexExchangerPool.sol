// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface INarfexP2pRouter {
    function swapTo(
        address to,
        address[] memory path,
        bool isExactOut,
        uint amount,
        uint amountLimit,
        uint deadline
    ) external payable;
}

/// @title Narfex Exchanger Pool
/// @notice Manages validator limits, fee handling, and pool balances
/// @author Danil Sakhinov
contract NarfexExchangerPool is Ownable {
    using Address for address;

    IERC20 public immutable token;
    address public immutable NRFX;
    address public router;
    address public masterChef;
    mapping(address => mapping(address => uint)) public validatorLimit;
    uint private feeAmount;

    uint256 constant MAX_INT = type(uint256).max;

    event RouterSet(address indexed routerAddress);
    event MasterChefSet(address indexed masterChefAddress);
    event FeeWithdrawn(uint feeAmount);
    event ValidatorLimitIncreased(address indexed validator, address fiat, uint amount);
    event ValidatorLimitDecreased(address indexed validator, address fiat, uint amount);

    /// @param _token Token used in the pool
    /// @param _routerAddress Address of the router
    /// @param _nrfxAddress Address of the NRFX token
    /// @param _masterChefAddress Address of the MasterChef contract
    constructor(
        address _token,
        address _routerAddress,
        address _nrfxAddress,
        address _masterChefAddress
    ) {
        token = IERC20(_token);
        router = _routerAddress;
        NRFX = _nrfxAddress;
        masterChef = _masterChefAddress;

        approveRouter();
    }

    modifier onlyRouterOrOwner() {
        require(msg.sender == owner() || msg.sender == router, "Access restricted to owner or router");
        _;
    }

    /// @notice Approves the router to transfer maximum token amount
    function approveRouter() public onlyRouterOrOwner {
        token.approve(router, MAX_INT);
    }

    /// @notice Sets a new router address
    /// @param _routerAddress New router address
    function setRouter(address _routerAddress) external onlyOwner {
        require(router != _routerAddress, "Router address already set");
        token.approve(router, 0); // Reset allowance for the old router
        router = _routerAddress;
        approveRouter();
        emit RouterSet(_routerAddress);
    }

    /// @notice Sets a new MasterChef address
    /// @param _masterChefAddress New MasterChef address
    function setMasterChef(address _masterChefAddress) external onlyOwner {
        require(masterChef != _masterChefAddress, "MasterChef address already set");
        masterChef = _masterChefAddress;
        emit MasterChefSet(_masterChefAddress);
    }

    /// @notice Withdraws tokens to the owner
    /// @param amount Amount to withdraw
    function withdraw(uint amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    /// @notice Withdraws another token to the owner
    /// @param amount Amount to withdraw
    /// @param tokenAddress Address of the token
    function withdrawToken(uint amount, address tokenAddress) external onlyOwner {
        require(tokenAddress != address(token), "Use withdraw() for the pool token");
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    /// @notice Increases validator limit for a fiat token
    /// @param validator Validator address
    /// @param fiatAddress Fiat token address
    /// @param amount Amount to increase
    function increaseValidatorLimit(address validator, address fiatAddress, uint amount) external onlyRouterOrOwner {
        validatorLimit[validator][fiatAddress] += amount;
        emit ValidatorLimitIncreased(validator, fiatAddress, amount);
    }

    /// @notice Decreases validator limit for a fiat token
    /// @param validator Validator address
    /// @param fiatAddress Fiat token address
    /// @param amount Amount to decrease
    function decreaseValidatorLimit(address validator, address fiatAddress, uint amount) external onlyRouterOrOwner {
        require(validatorLimit[validator][fiatAddress] >= amount, "Insufficient validator limit");
        validatorLimit[validator][fiatAddress] -= amount;
        emit ValidatorLimitDecreased(validator, fiatAddress, amount);
    }

    /// @notice Returns validator limit for a fiat token
    /// @param validator Validator address
    /// @param fiatAddress Fiat token address
    function getValidatorLimit(address validator, address fiatAddress) external view returns (uint) {
        return validatorLimit[validator][fiatAddress];
    }

    /// @notice Increases fee amount in the pool
    /// @param amount Fee amount to increase
    function increaseFeeAmount(uint amount) external onlyRouterOrOwner {
        feeAmount += amount;
    }

    /// @notice Sends accumulated fees to the MasterChef contract in NRFX
    function sendFeeToMasterChef() external onlyRouterOrOwner {
        require(feeAmount > 0, "No fees to withdraw");

        address;
        path[0] = address(token);
        path[1] = NRFX;

        INarfexP2pRouter(router).swapTo(masterChef, path, false, feeAmount, 0, block.timestamp + 20 minutes);

        emit FeeWithdrawn(feeAmount);
        feeAmount = 0;
    }

    /// @notice Gets the current fee amount in the pool
    function getFeeAmount() external view returns (uint) {
        return feeAmount;
    }
}
