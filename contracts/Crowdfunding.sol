// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Crowdfunding is ReentrancyGuard {
    address public creator;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalContributions;
    bool public funded;
    
    mapping(address => uint256) public contributions;
    address[] public contributors;
    
    event Contribution(address indexed contributor, uint256 amount);
    event GoalReached(uint256 total);
    event Refund(address indexed contributor, uint256 amount);
    event FundsWithdrawn(uint256 amount);
    
    constructor(uint256 _goal, uint256 _duration) {
        creator = msg.sender;
        goal = _goal;
        deadline = block.timestamp + _duration;
    }
    
    function contribute() external payable nonReentrant {
        require(block.timestamp < deadline, "Campaign ended");
        require(!funded, "Goal already reached");
        require(msg.value > 0, "Must contribute something");
        
        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }
        
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        
        emit Contribution(msg.sender, msg.value);
        
        if (totalContributions >= goal) {
            funded = true;
            emit GoalReached(totalContributions);
        }
    }
    
    function withdraw() external nonReentrant {
        require(msg.sender == creator, "Only creator");
        require(funded, "Goal not reached");
        uint256 amount = address(this).balance;
        payable(creator).transfer(amount);
        emit FundsWithdrawn(amount);
    }
    
    function getRefund() external nonReentrant {
        require(block.timestamp >= deadline, "Campaign still active");
        require(!funded, "Goal was reached");
        require(contributions[msg.sender] > 0, "No contribution");
        
        uint256 amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Refund(msg.sender, amount);
    }
}
