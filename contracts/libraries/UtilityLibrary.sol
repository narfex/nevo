// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title UtilityLibrary
/// @notice Provides common utility functions for smart contracts
library UtilityLibrary {
    /// @notice Converts an `address` to its string representation
    /// @param account The address to convert
    /// @return result The string representation of the address
    function addressToString(address account) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(account);
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(42);

        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = hexChars[uint8(data[i] >> 4)];
            str[3 + i * 2] = hexChars[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }

    /// @notice Converts a `uint256` to its string representation
    /// @param value The number to convert
    /// @return result The string representation of the number
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    /// @notice Checks if a string is empty
    /// @param str The string to check
    /// @return isEmpty True if the string is empty, false otherwise
    function isEmptyString(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    /// @notice Combines two strings
    /// @param a First string
    /// @param b Second string
    /// @return result The concatenated string
    function concatStrings(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    /// @notice Checks if an address is a contract
    /// @param account The address to check
    /// @return isContract True if the address is a contract, false otherwise
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /// @notice Returns the current block timestamp in a formatted manner (e.g., days since epoch)
    /// @return timestamp Current block timestamp
    function getCurrentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    /// @notice Safely casts a `uint256` to a `uint8`
    /// @param value The value to cast
    /// @return castValue The casted value
    function safeCastToUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "UtilityLibrary: value too large for uint8");
        return uint8(value);
    }
}
