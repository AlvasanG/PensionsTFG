// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Pensioner.sol";

/// @title A representation of a pension system
/// @author Alvaro Sánchez García
/// @dev This contract is intended to be run with Pensioner.sol
/// @dev The use of a PROPORTION_FACTOR is to workaround the non existance of floating numbers
/// @notice All timestamps are expressed using Unix time https://en.wikipedia.org/wiki/Unix_time
/// @notice All durations are expressed in seconds
contract PensionSystem is ReentrancyGuard {
    mapping(address => Pensioner) public pensioners;
    mapping(address => uint8) public isPensionerCreated;
    address payable[] public pensionerList;
    uint256 public createdAtTime;
    uint256 public lastPayoutDate;
    uint256 public payoutInterval;

    mapping(address => uint256) private _pensionerAmount;
    address[] private _pensioners;

    /// @notice Creates a pension system
    /// @param _payoutInterval The interval at which the payouts will roll out
    constructor(uint256 _payoutInterval) public ReentrancyGuard() {
        createdAtTime = block.timestamp;
        lastPayoutDate = createdAtTime;
        payoutInterval = _payoutInterval;
    }

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

    /// @notice Changes a pensioner retirement time
    /// @dev The pensioner must exist
    /// @dev The date of retirement must be a future one
    /// @dev The pensioner must not be retired
    function setRetirementTime(uint256 retireDate) public {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        require(retireDate >= block.timestamp, "Date must be a future one");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Pensioner cannot retire after being retired"
        );
        pensioners[msg.sender].setRetirement(retireDate);
    }

    /// @notice Changes a pensioner retirement time for now
    /// @dev The pensioner must exist
    /// @dev The pensioner must not be retired
    function setRetirementTimeNow() public {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Pensioner cannot retire after being retired"
        );
        pensioners[msg.sender].setRetirementNow();
    }

    /// @notice Changes a pensioner benefit duration
    /// @dev The pensioner must exist
    /// @dev The duration must be positive
    /// @dev The pension must be active
    function setBenefitDuration(uint256 benefitDuration) public {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        require(benefitDuration >= 0, "Duration must be greater than 0");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            pensioner.getFinishPensionTime() >= block.timestamp,
            "Pensioner cannot increase benefit duration after it has expired"
        );
        pensioners[msg.sender].setBenefitDuration(benefitDuration);
    }

    /// @notice Adds an amount to the pension attributable to a pensioner
    /// @dev The pensioner must exist
    /// @dev The pensioner must not be retired
    function fundPension() public payable {
        require(isPensionerCreated[msg.sender] > 0, "Pensioner does not exist");
        Pensioner pensioner = pensioners[msg.sender];
        require(
            !pensioner.isPensionerRetired(),
            "Cannot contribute to a retired account"
        );
        pensioner.addContribution(msg.value);
    }

    /// @notice Calculates the state of the pension system
    /// @notice Pays the pensions to the elegible pensioners
    /// @dev The pensioner must be retired
    /// @dev The pensioner must have an active benefit window
    /// @dev The pensioner must have funded the system
    function calculateState() public nonReentrant {
        if (lastPayoutDate + payoutInterval > block.timestamp) {
            return;
        } else {
            lastPayoutDate = block.timestamp;
        }
        uint256 agreggatedContributions = 0;
        uint256 totalToBeDistributed = getTotalToBeDistributed();

        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            if (
                pensioner.isPensionerRetired() &&
                pensioner.isInsideBenefitDuration() &&
                pensioner.totalContributedAmount() > 0
            ) {
                agreggatedContributions += pensioner.getWeightedContribution();
            }
        }

        uint256 totalSplitPayout = 0;
        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            if (
                pensioner.isPensionerRetired() &&
                pensioner.isInsideBenefitDuration() &&
                pensioner.totalContributedAmount() > 0
            ) {
                uint256 pensionerPayout = 0;
                if (i == pensionerList.length - 1) {
                    pensionerPayout = totalToBeDistributed - totalSplitPayout;
                } else {
                    uint256 contributedByPensioner = pensioner
                        .getWeightedContribution();
                    pensionerPayout =
                        (contributedByPensioner * totalToBeDistributed) /
                        agreggatedContributions;
                    totalSplitPayout += pensionerPayout;
                }

                _pensioners.push(pensionerAdd);
                _pensionerAmount[pensionerAdd] = pensionerPayout;
            }
        }

        for (uint256 i = 0; i < _pensioners.length; i++) {
            address pensionerAdd = _pensioners[i];
            uint256 amount = _pensionerAmount[pensionerAdd];
            payable(pensionerAdd).transfer(amount);
            delete _pensionerAmount[pensionerAdd];
        }
        delete _pensioners;
    }

    /// @notice Returns the mapping of pensioners in 2 separate arrays, one for address and another for
    /// @notice pensioner address
    /// @dev It is a workaround since we cannot return a mapping directly
    function getPensionerList()
        public
        view
        returns (address[] memory, Pensioner[] memory)
    {
        address[] memory mAddresses = new address[](pensionerList.length);
        Pensioner[] memory mPensioners = new Pensioner[](pensionerList.length);
        for (uint256 i = 0; i < pensionerList.length; i++) {
            mAddresses[i] = pensionerList[i];
            mPensioners[i] = pensioners[pensionerList[i]];
        }
        return (mAddresses, mPensioners);
    }

    /// @notice Calculates the total to be distributed based on the ratio of pensioners and contributors
    /// @dev Only takes into account active pensioners and active contributors
    /// @dev The value is given by the formula (lambda * (balance * 0.90))
    /// @dev Lambda is the ratio
    /// @dev The balance is not 100% given possible gas costs
    function getTotalToBeDistributed() private view returns (uint256) {
        uint256 lambda = 0;
        uint256 numberOfContributors = 0;
        uint256 numberOfPensioners = 0;
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < pensionerList.length; i++) {
            address pensionerAdd = pensionerList[i];
            Pensioner pensioner = pensioners[pensionerAdd];
            if (pensioner.isPensionerRetired()) {
                if (pensioner.isInsideBenefitDuration()) {
                    numberOfPensioners++;
                }
            } else if (pensioner.totalContributedAmount() > 0) {
                numberOfContributors++;
            }
        }
        if (numberOfPensioners == 0) {
            return 0;
        }
        if (numberOfContributors == 0) {
            return (balance * 20) / 100;
        }
        if (numberOfContributors > numberOfPensioners) {
            return (balance * 90) / 100;
        }
        lambda = (numberOfContributors * 100) / numberOfPensioners;
        return (((balance * 90) / 100) * lambda) / 100;
    }
}
