// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

contract SavingsAccount {
    mapping(address => uint256) public balanceOf;

    function deposit(uint256 amount) public payable {
        require(msg.value == amount);
        balanceOf[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public payable {
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }

    function withdrawAll() public payable {
        uint256 fullAmount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(fullAmount);
    }

    function transferFunds(uint256 amount, address toAccount) public payable {
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        (bool success, ) = toAccount.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getBalance() public view returns (uint256) {
        return balanceOf[msg.sender];
    }
}
