// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Pensioner.sol";

/// @title A representation of a pension system
/// @author Alvaro Sánchez García
/// @dev This contract is intended to be run with Pensioner.sol
/// @dev The use of a PROPORTION_FACTOR is to workaround the non existance of floating numbers
/// @notice All timestamps are expressed using Unix time https://en.wikipedia.org/wiki/Unix_time
contract PensionSystem is ReentrancyGuard {
    uint256 private PROPORTION_FACTOR = 10**18;

    uint256 public balance;
    mapping(address => Pensioner) public pensioners;
    mapping(address => uint8) public isPensionerCreated;
    address payable[] public pensionerList;

    mapping(address => uint256) private pensionerAmount;
    address[] private pensioners;

    // Functionality based events

    // Testing based events
    event Deposited(uint256 totalPayedSincePayout);
    event Paid(uint256 totalPayedSincePayout, uint256 totalContributed);
    event UserInfo(
        uint256 currentBlock,
        bool isRetired,
        uint256 finishPensionTime,
        uint256 totalContributed
    );

    constructor() public ReentrancyGuard() {}

    /// @notice Creates a pensioner
    /// @dev The address must not be already registered
    /// @dev The retirementTime must be a future date
    /// @param retirementTime Timestamp at which the new pensioner wants to retire
    /// @param benefitWindowTime Timestamp representing the amount of time the pensioner will be elegible for benefits
    function createPensioner(uint256 retirementTime, uint256 benefitWindowTime)
        public
    {
        require(
            retirementTime >= block.timestamp,
            "Can not retire before creating the account"
        );
        require(
            isPensionerCreated[msg.sender] == 0,
            "Pensioner already exists"
        );
        Pensioner pensioner = new Pensioner(retirementTime, benefitWindowTime);
        pensioners[msg.sender] = pensioner;
        isPensionerCreated[msg.sender] = 1;
        pensionerList.push(msg.sender);
    }

    /// @notice Retires a pensioner at the current block timestamp
    /// @dev The pensioner must exist
    /// @dev The pensioner must not be retired
    function retirePensioner() public {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Pensioner cannot retire after being retired"
        );
        pensioners[msg.sender].setRetirementNow();
    }

    /// @notice Adds an amount to the pension attributable to a pensioner
    /// @dev The pensioner must exist
    /// @dev The pensioner must not be retired
    /// @dev The contribution must be a nonnegative value
    function fundPension() public payable {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Cannot contribute to a retired account"
        );
        require(
            pensioner.retireAtTime() >= block.timestamp,
            "Cannot contribute to a retired account"
        );
        require(msg.value >= 0, "Cannot contribute with a negative value");
        balance += msg.value;
        user.addContribution(msg.value);
    }

    /// @notice Calculates the state of the pension system
    /// @notice Pays the pensions to the elegible pensioners
    /// @dev The pensioner must be retired
    /// @dev The pensioner must have an active benefit window
    /// @dev The pensioner must have funded the system
    function calculateState() public nonReentrant {
        uint256 totalToPay = 0;
        uint256 totalPayedSincePayout = 0;

        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            emit UserInfo(
                block.timestamp,
                pensioner.isPensionerRetired(),
                pensioner.finishPensionTime(),
                pensioner.totalContributedAmount()
            );
            if (!pensioner.isUserRetired()) {
                continue;
            } else if (pensioner.finishPensionTime() < block.timestamp) {
                continue;
            } else if (pensioner.totalContributedAmount() == 0) {
                continue;
            }
            totalPayedSincePayout += pensioner.totalContributedAmount();
            emit Paid(
                totalPayedSincePayout,
                pensioner.totalContributedAmount()
            );
        }

        emit Deposited(totalPayedSincePayout);

        uint256 totalSplittedPayout = 0;
        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            if (!pensioner.isPensionerRetired()) {
                continue;
            } else if (pensioner.finishPensionTime() < block.timestamp) {
                continue;
            } else if (pensioner.totalContributedAmount() == 0) {
                continue;
            }

            uint256 pensionerPayout = 0;
            if (i == pensionerList.length - 1) {
                pensionerPayout = balance - totalSplittedPayout;
            } else {
                uint256 contributedProportionByUser = (pensioner
                    .totalContributedAmount() * PROPORTION_FACTOR) /
                    totalPayedSincePayout;
                pensionerPayout =
                    (contributedProportionByUser * balance) /
                    PROPORTION_FACTOR;
                totalSplittedPayout += pensionerPayout;
            }
            totalToPay += pensionerPayout;

            pensioners.push(pensionerAdd);
            pensionerAmount[pensionerAdd] = pensionerPayout;
        }

        balance -= totalToPay;
        for (uint256 i = 0; i < pensioners.length; i++) {
            address pensionerAdd = pensioners[i];
            uint256 amount = pensionerAmount[pensionerAdd];
            payable(pensionerAdd).transfer(amount);
            delete pensionerAmount[pensionerAdd];
        }

        delete pensioners;
    }
}
