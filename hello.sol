// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdfundingWithRewards {
    // State variables
    address public owner;
    uint public goal;
    uint public deadline;
    uint public fundsRaised;
    bool public goalReached;

    // Mapping to keep track of investors' contributions
    mapping(address => uint) public contributions;
    mapping(address => uint) public rewards;

    // Events
    event ContributionReceived(address contributor, uint amount);
    event GoalReached(uint totalAmountRaised);
    event FundsWithdrawn(address recipient, uint amount);
    event RefundIssued(address contributor, uint amount);
    event RewardIssued(address contributor, uint reward);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyBeforeDeadline() {
        require(block.timestamp < deadline, "Can only be called before deadline");
        _;
    }

    modifier onlyAfterDeadline() {
        require(block.timestamp >= deadline, "Can only be called after deadline");
        _;
    }

    // Constructor
    constructor(uint _goal, uint _durationInMinutes) {
        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + (_durationInMinutes * 1 minutes);
    }

    // Function to contribute to the crowdfunding campaign
    function contribute() public payable onlyBeforeDeadline {
        require(msg.value > 0, "Contribution must be greater than zero");

        contributions[msg.sender] += msg.value;
        fundsRaised += msg.value;

        // Calculate and issue rewards based on contribution amount
        uint reward = calculateReward(msg.value);
        rewards[msg.sender] += reward;

        emit ContributionReceived(msg.sender, msg.value);
        emit RewardIssued(msg.sender, reward);

        if (fundsRaised >= goal) {
            goalReached = true;
            emit GoalReached(fundsRaised);
        }
    }

    // Function to calculate rewards based on contribution amount
    function calculateReward(uint _amount) internal pure returns (uint) {
        // Example reward calculation: 1 reward point per ether contributed
        return _amount / 1 ether;
    }

    // Function for the owner to withdraw funds if the goal is reached
    function withdrawFunds() public onlyOwner onlyAfterDeadline {
        require(owner==msg.sender,"Only owner can withdraw funds");
        require(goalReached, "Goal not reached, cannot withdraw funds");

        uint amount = address(this).balance;
        payable(owner).transfer(amount);

        emit FundsWithdrawn(owner, amount);
    }

    // Function to refund contributors if the goal is not reached
    function refund() public onlyAfterDeadline {
        require(!goalReached, "Goal was reached, cannot refund");

        uint contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contributions to refund");

        contributions[msg.sender] = 0;
        rewards[msg.sender] = 0;  // Reset rewards as well
        payable(msg.sender).transfer(contributedAmount);

        emit RefundIssued(msg.sender, contributedAmount);
    }

    // Function to check the remaining time for the campaign
    function timeLeft() public view returns (uint) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Function to check rewards for a contributor
    function checkReward(address _contributor) public view returns (uint) {
        return rewards[_contributor];
}
}
