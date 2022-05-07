// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/// @title A mock of a savings account
/// @author Alvaro Sánchez García
contract SavingsAccount {
    mapping(address => uint256) public balanceOf;

    /// @notice Deposits a given amount on the account
    /// @param amount The new value to be added to the account
    function deposit(uint256 amount) public payable {
        require(msg.value == amount);
        balanceOf[msg.sender] += amount;
    }

    /// @notice Withdraws a given amount from the account
    /// @param amount The value to be withdrawn
    function withdraw(uint256 amount) public payable {
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }

    /// @notice Withdraws the total amount on the account
    function withdrawAll() public payable {
        uint256 fullAmount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(fullAmount);
    }

    /// @notice Transfer a given amount between this account and another address
    /// @param amount The value to transfer
    /// @param toAccount The account to tranfer the funds to
    function transferFunds(uint256 amount, address toAccount) public payable {
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        (bool success, ) = toAccount.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /// @notice Return the balance of the account
    /// @return The balance of the account
    function getBalance() public view returns (uint256) {
        return balanceOf[msg.sender];
    }
}
