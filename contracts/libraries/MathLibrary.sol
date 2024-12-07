// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title MathLibrary
/// @notice A library for common mathematical operations
library MathLibrary {
    /// @notice Returns the square root of a given number
    /// @param x Input number
    /// @return y Square root of the input number
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Calculates the absolute difference between two numbers
    /// @param a First number
    /// @param b Second number
    /// @return Difference Absolute difference between `a` and `b`
    function absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    /// @notice Returns the minimum of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return Minimum of `a` and `b`
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Returns the maximum of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return Maximum of `a` and `b`
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @notice Multiplies two numbers and divides by a denominator with precision
    /// @param a Numerator 1
    /// @param b Numerator 2
    /// @param denominator Denominator
    /// @return result Result of (a * b) / denominator
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        require(denominator > 0, "MathLibrary: denominator cannot be zero");
        uint256 prod0 = a * b; // Least significant 256 bits of the product
        require(prod0 / a == b, "MathLibrary: multiplication overflow");

        result = prod0 / denominator;
    }

    /// @notice Calculates the power of a number
    /// @param base The base number
    /// @param exponent The exponent
    /// @return result `base` raised to the power of `exponent`
    function power(uint256 base, uint256 exponent) internal pure returns (uint256 result) {
        result = 1;
        for (uint256 i = 0; i < exponent; i++) {
            result *= base;
        }
    }
}
