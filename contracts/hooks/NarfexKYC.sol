//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "@uniswap/v4-core/src/interfaces/IPoolManager.sol";


/// @title KYC verifications, validators, and blacklist with Hook support for Narfex P2P service

contract NarfexKYC is Ownable, IHooks {

    mapping(address => string) private _clients;
    mapping(address => bool) private _verificators;
    mapping(address => bool) private _blacklisted;
    address public writer;

    constructor() {
        setWriter(msg.sender);
    }

    event SetWriter(address _account);
    event Verify(address _account);
    event RevokeVerification(address _account);
    event AddVerificator(address _account);
    event RemoveVerificator(address _account);
    event Blacklisted(address _account);
    event Unblacklisted(address _account);
    event BeforeSwap(address indexed sender, address indexed token0, address indexed token1, uint256 amountSpecified);
    event AfterSwap(address indexed sender, address indexed token0, address indexed token1, uint256 amountOut);

    modifier canWrite() {
        require(msg.sender == owner() || msg.sender == writer, "No permission");
        _;
    }

    modifier onlyWriter() {
        require(msg.sender == writer, "Only writer can do it");
        _;
    }

    /// @notice Set writer account
    /// @param _account New writer account address
    function setWriter(address _account) public onlyOwner {
        writer = _account;
        emit SetWriter(_account);
    }

    /// @notice Check if an account is KYC verified
    /// @param _client Account address
    /// @return True if the contract has personnel data for this account
    function isKYCVerified(address _client) public view returns (bool) {
        return bytes(_clients[_client]).length > 0;
    }

    /// @notice Verify the account
    /// @param _account Account address
    /// @param _data Encrypted JSON encoded account personnel data
    function verify(address _account, string calldata _data) public onlyWriter {
        require(bytes(_data).length > 0, "Data can't be empty");
        _clients[_account] = _data;
        emit Verify(_account);
    }

    /// @notice Revoke KYC verification for an account
    /// @param _account Account address
    function revokeVerification(address _account) public canWrite {
        _clients[_account] = "";
        emit RevokeVerification(_account);
    }

    /// @notice Get personnel data for accounts
    /// @param _accounts Array of addresses
    /// @return Array of encrypted personnel data strings
    function getData(address[] calldata _accounts) public view returns (string[] memory) {
        string[] memory data = new string[](_accounts.length);
        for (uint i = 0; i < _accounts.length; i++) {
            data[i] = _clients[_accounts[i]];
        }
        return data;
    }

    /// @notice Add an account to the list of verificators
    /// @param _account Account address
    function addVerificator(address _account) public onlyWriter {
        _verificators[_account] = true;
        emit AddVerificator(_account);
    }

    /// @notice Remove an account from the list of verificators
    /// @param _account Account address
    function removeVerificator(address _account) public canWrite {
        _verificators[_account] = false;
        emit RemoveVerificator(_account);
    }

    /// @notice Blacklist an account
    /// @param _account Account address
    function addToBlacklist(address _account) public canWrite {
        _blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /// @notice Remove an account from the blacklist
    /// @param _account Account address
    function removeFromBlacklist(address _account) public canWrite {
        _blacklisted[_account] = false;
        emit Unblacklisted(_account);
    }

    /// @notice Check if an account is blacklisted
    /// @param _account Account address
    /// @return True if the account is blacklisted
    function getIsBlacklisted(address _account) public view returns (bool) {
        return _blacklisted[_account];
    }

    /// @notice Check if an account can trade
    /// @param _account Account address
    /// @return True if the account is verified, not blacklisted, and a verificator
    function getCanTrade(address _account) public view returns (bool) {
        return _verificators[_account] && !getIsBlacklisted(_account) && isKYCVerified(_account);
    }

    /// @notice Hook called before a swap to enforce KYC and blacklist checks
    function beforeSwap(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params,
        bytes calldata hookData
    ) external override {
        require(!getIsBlacklisted(sender), "Sender is blacklisted");
        require(isKYCVerified(sender), "KYC verification required");
        emit BeforeSwap(sender, key.token0, key.token1, params.amountSpecified);
    }

    /// @notice Hook called after a swap
    function afterSwap(
        address sender,
        IPoolManager.PoolKey memory key,
        IPoolManager.SwapParams memory params,
        IPoolManager.BalanceDelta memory swapDelta,
        bytes calldata hookData
    ) external override {
        emit AfterSwap(sender, key.token0, key.token1, uint256(swapDelta.amountOut));
    }

    /// @notice Returns the hooks this contract implements
    function getHooksCalls() external pure override returns (Hooks.Memory memory) {
        return Hooks.Memory({beforeSwap: true, afterSwap: true});
    }
}
