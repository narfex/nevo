// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title AddressUtils
/// @notice Utility library for address-related functions
library AddressUtils {
    /**
     * @notice Checks if the given address is a contract
     * @param account The address to check
     * @return True if the address is a contract, false otherwise
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Sends Ether to the specified address
     * @param recipient The address to send Ether to
     * @param amount The amount of Ether to send
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "AddressUtils: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "AddressUtils: unable to send value");
    }

    /**
     * @notice Performs a low-level function call
     * @param target The address to call
     * @param data The data to send to the address
     * @return The raw returned data from the call
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "AddressUtils: low-level call failed");
    }

    /**
     * @notice Performs a low-level function call with a custom error message
     * @param target The address to call
     * @param data The data to send to the address
     * @param errorMessage A custom error message in case of failure
     * @return The raw returned data from the call
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "AddressUtils: call to non-contract");

        (bool success, bytes memory returndata) = target.call(data);
        if (success) {
            return returndata;
        } else {
            // Handle revert reason and bubble it up
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
