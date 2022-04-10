//SPDX-License-Identifier: MIT

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

/**
    @author Manuel Aguilar
    @title ETHPool
    @notice A contract that allows users to have a share on an ETH pool and receive rewards based on the share of
    the pool they own
 */

contract ETHPool {
    /**
        @notice Struct to save a user's current share of the pool
     */
    struct Share {
        address owner;
        uint256 absValue;
    }
    /**
        @notice Stores the addreses that can deposit a reward
     */
    mapping(address => bool) public teamAddresses;
    /**
        @notice Current balance of the contract
     */
    uint256 public contractBalance;
    /**
        @notice Array of user's shares on the contract
     */
    Share[] public shareBalances;

    /**
        @notice Set the teamAddresses mapping
     */
     
    /**
        @notice Event emitted when someone deposits
        @param depositer The address that has made the deposit
        @param amount Amount deposited in WEIs
        @param isReward true if this deposit has been distributed as a reward to shareholders
     */
    event Deposit(address indexed depositer, uint256 amount, bool isReward);

    /**
        @notice Event emitted when someone withdraws their share
        @param shareholder The address that withdrew their share
        @param amount Amount withdrawn in WEIs
     */
    event Withdrawn(address indexed shareholder, uint256 amount);

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
    
    /**
        @notice Function that lets users deposit and if they are a team member as per the teamAddresses mapping their
        deposit will be distributed as a reward to all current user shares, if not, it will be added as their share 
        of the contract. In any case, the deposit will be added to the contract balance.
     */
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

    /**
        @notice Function that lets a user withdraw their share from the contract
     */
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

    /**
        @notice Function that lets a user check the current share balance of an address
        on this contract.
     */
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
