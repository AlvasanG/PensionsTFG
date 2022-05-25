// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/// @title A representation of a pensioner
/// @author Alvaro Sánchez García
/// @dev This contract is intended to be run with PensionSystem.sol
/// @notice All timestamps are expressed using Unix time https://en.wikipedia.org/wiki/Unix_time
contract Pensioner {
    uint256 public totalContributedAmount;
    uint256 public createdAtTime;
    uint256 public retireAtDate;
    uint256 public benefitDuration;

    /// @notice Creates a pensioner
    /// @param _retireAtDate Timestamp at which the new pensioner wants to retire
    /// @param _benefitDuration Timestamp representing the amount of time the pensioner will be elegible for benefits
    constructor(uint256 _retireAtDate, uint256 _benefitDuration) public {
        totalContributedAmount = 0;
        createdAtTime = block.timestamp;
        retireAtDate = _retireAtDate;
        benefitDuration = _benefitDuration;
    }

    /// @notice Retires a pensioner at the current block timestamp
    /// @dev We substract one just in case block.timestamp doesnt change when performing the next operation
    function setRetirementNow() public {
        retireAtDate = block.timestamp - 1;
    }

    /// @notice Retires a pensioner at a given date
    function setRetirement(uint256 retireDate) public {
        require(retireDate >= block.timestamp, "Date must be a future one");
        retireAtDate = retireDate;
    }

    /// @notice Adds a contribution to the total amount contributed by the pensioner
    /// @param amount The new value to be added to the total amount
    function addContribution(uint256 amount) public {
        require(
            !isPensionerRetired(),
            "Pensioner must be active to contribute"
        );
        totalContributedAmount += amount;
    }

    /// @notice Returns the date at which the pensioner will stop receiving funds
    function getFinishPensionTime() public view returns (uint256) {
        return retireAtDate + benefitDuration;
    }

    /// @notice Returns whether a pensioner is retired or not
    function isPensionerRetired() public view returns (bool) {
        return retireAtDate <= block.timestamp;
    }
}
