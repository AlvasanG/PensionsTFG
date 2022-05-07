// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/// @title A representation of a pensioner
/// @author Alvaro Sánchez García
/// @dev This contract is intended to be run with PensionAccount.sol
/// @notice All timestamps are expressed using Unix time https://en.wikipedia.org/wiki/Unix_time
contract Pensioner {
    uint256 public totalContributedAmount = 0;
    uint256 public createdAtTime;
    uint256 public retireAtTime;
    uint256 public benefitUntilTime;
    uint256 public finishPensionTime;
    bool public isUserRetired = false;

    /// Creates a pensioner given two parameters
    /// @param retirementTime Timestamp at which the new pensioner wants to retire
    /// @param benefitWindowTime Timestamp representing the amount of time the pensioner will be
    /// elegible for benefits
    constructor(uint256 retirementTime, uint256 benefitWindowTime) public {
        createdAtTime = block.timestamp;
        retireAtTime = retirementTime;
        benefitUntilTime = benefitWindowTime;
        finishPensionTime = retireAtTime + benefitUntilTime;
    }

    /// Retires a pensioner at the current block timestamp
    function setRetirementNow() public {
        setIsRetired(true);
        retireAtTime = block.timestamp - 1;
        finishPensionTime = block.timestamp - 1 + benefitUntilTime;
    }

    /// Sets a pensioner retired flag
    /// @param retired The new value of the flag
    function setIsRetired(bool retired) private {
        isUserRetired = retired;
    }

    /// Adds a contribution to the total amount contributed by the pensioner
    /// @param amount The new value to be added to the total amount
    function addContribution(uint256 amount) public {
        totalContributedAmount += amount;
    }
}
