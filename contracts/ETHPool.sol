//SPDX-License-Identifier: Unlicense

// 1) Setup a project and create a contract
// Summary
// ETHPool provides a service where people can deposit ETH and they will receive weekly rewards.
//  Users must be able to take out their deposits along with their portion of rewards at any time. 
// New rewards are deposited manually into the pool by the ETHPool team each week using a contract function.

// Requirements
// Only the team can deposit rewards.
// Deposited rewards go to the pool of users, not to individual users.
// Users should be able to withdraw their deposits along with their 
// share of rewards considering the time when they deposited.

pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract ETHPool {
    struct Share {
        address owner;
        uint256 absValue;
    }
    mapping(address => bool) public teamAddresses;
    uint256 public contractBalance;
    Share[] public shareBalances;

    constructor(address[] memory _teamAddresses) {
        console.log("Deploying an ETHPool contract with team size:", _teamAddresses.length);
        for (uint128 index = 0; index < _teamAddresses.length; index++) {
            teamAddresses[_teamAddresses[index]] = true;
        }
    }
    // Looping through the shareBalances array is a known risk it can maybe be mitigated by having a min value check
    // so no one can deposit small values with a lot of accounts. Also a way to do the loop in batches can be 
    // implemented.
    // There may be an overflow problem too when calculating the reward but I'm not sure it's possible
    // to reach the wei values to overflow uint256
    function deposit() public payable {
        if(teamAddresses[msg.sender] == true){
            // Calculate and deposit rewards
            for (uint256 index = 0; index < shareBalances.length; index++) {
                // Calculate what number this % of the total represents
                uint256 rewardValue = ((shareBalances[index].absValue * msg.value) / contractBalance); 
                // Update share of the total value deposited on the contract w/ reward
                shareBalances[index].absValue += rewardValue; 
            }
        } else {
            // Update share absValues
            for (uint256 index = 0; index < shareBalances.length; index++) {
                if(shareBalances[index].owner == msg.sender){
                    shareBalances[index].absValue += msg.value;
                    break;
                }
                if(index == shareBalances.length - 1){
                    // Arbitrary value to demonstrate a way to protect from denial of service attacks
                    require(msg.value > 0.1 ether, "Can't deposit less than 0.1 eth"); 
                    shareBalances.push(Share(msg.sender, msg.value));
                    break;
                }
            }
        }
        //Update contract balance
        contractBalance += msg.value;
    }

    function withdraw() public{
        //Loop through share array and send corresponding absValue
        uint256 withdrawValue;
        for (uint256 index = 0; index < shareBalances.length; index++) {
            if(shareBalances[index].owner == msg.sender){
                withdrawValue = shareBalances[index].absValue;
                shareBalances[index] = shareBalances[shareBalances.length - 1];
                shareBalances.pop();
                break;
            }
        }
        (bool sent, ) = payable(msg.sender).call{value: withdrawValue}("");
        require(sent, "Failed to send Ether");
    }

    function balanceOf(address _address) public view returns (uint){
        //Loop through share array and return abs value
        for (uint256 index = 0; index < shareBalances.length; index++) {
            if(shareBalances[index].owner == _address){
                return shareBalances[index].absValue;
            }
        }
        return 0;
    }
}
