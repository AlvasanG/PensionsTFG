// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Pensioner.sol";

contract PensionAccount is ReentrancyGuard {
    mapping(address => Pensioner) public pensionUsers;
    mapping(address => uint8) public isUserCreated;
    address payable[] public userList;

    mapping(address => uint256) private userAmount;
    address[] private users;

    uint256 public balance;
    uint256 private kProportionFactor = 10**18;

    event Deposited(uint256 totalPayedSincePayout);
    event Paid(uint256 totalPayedSincePayout, uint256 totalContributed);
    event UserInfo(
        uint256 currentBlock,
        bool isRetired,
        uint256 finishPensionTime,
        uint256 totalContributed
    );

    constructor() public ReentrancyGuard() {}

    function createUser(uint256 retireAtTime, uint256 benefitWindowTime)
        public
    {
        require(
            retireAtTime >= block.timestamp,
            "Can not retire before creating the account"
        );
        require(isUserCreated[msg.sender] == 0, "User already exists");
        Pensioner user = new Pensioner(retireAtTime, benefitWindowTime);
        pensionUsers[msg.sender] = user;
        isUserCreated[msg.sender] = 1;
        userList.push(msg.sender);
    }

    function retireUser() public {
        require(isUserCreated[msg.sender] > 0, "User does not exist");
        Pensioner user = pensionUsers[msg.sender];
        require(
            !user.isUserRetired(),
            "User cannot retire after being retired"
        );
        pensionUsers[msg.sender].setRetirementNow();
    }

    function fundPension() public payable {
        require(isUserCreated[msg.sender] > 0, "User does not exist");
        Pensioner user = pensionUsers[msg.sender];
        require(
            !user.isUserRetired(),
            "Cannot contribute to a retired account"
        );
        require(
            user.retireAtTime() >= block.timestamp,
            "Cannot contribute to a retired account"
        );
        require(msg.value >= 0, "Cannot contribute with a negative value");
        balance += msg.value;
        user.addContribution(msg.value);
    }

    function calculateState() public nonReentrant {
        uint256 totalToPay = 0;
        uint256 totalPayedSincePayout = 0;

        for (uint256 i = 0; i < userList.length; i++) {
            address userAdd = userList[i];
            Pensioner user = pensionUsers[userAdd];
            emit UserInfo(
                block.timestamp,
                user.isUserRetired(),
                user.finishPensionTime(),
                user.totalContributedAmount()
            );
            if (!user.isUserRetired()) {
                continue;
            } else if (user.finishPensionTime() < block.timestamp) {
                continue;
            } else if (user.totalContributedAmount() == 0) {
                continue;
            }
            totalPayedSincePayout += user.totalContributedAmount();
            emit Paid(totalPayedSincePayout, user.totalContributedAmount());
        }

        emit Deposited(totalPayedSincePayout);

        uint256 totalSplittedPayout = 0;
        for (uint256 i = 0; i < userList.length; i++) {
            address userAdd = userList[i];
            Pensioner user = pensionUsers[userAdd];
            if (!user.isUserRetired()) {
                continue;
            } else if (user.finishPensionTime() < block.timestamp) {
                continue;
            } else if (user.totalContributedAmount() == 0) {
                continue;
            }

            uint256 userPayout = 0;
            if (i == userList.length - 1) {
                userPayout = balance - totalSplittedPayout;
            } else {
                uint256 contributedProportionByUser = (user
                    .totalContributedAmount() * kProportionFactor) /
                    totalPayedSincePayout;
                userPayout =
                    (contributedProportionByUser * balance) /
                    kProportionFactor;
                totalSplittedPayout += userPayout;
            }
            totalToPay += userPayout;

            users.push(userAdd);
            userAmount[userAdd] = userPayout;
        }

        balance -= totalToPay;
        for (uint256 i = 0; i < users.length; i++) {
            address userAdd = users[i];
            uint256 amount = userAmount[userAdd];
            payable(userAdd).transfer(amount);
            delete userAmount[userAdd];
        }

        delete users;
    }
}
