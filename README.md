# Staking Module

## Overview
This Staking Module is a smart contract written in Solidity for staking and earning rewards using two ERC-20 tokens. Users can stake a specified amount of staking tokens and earn rewards in a separate token when rewards are accrued. The contract dynamically calculates and updates the reward rate based on the staking and rewards token balances. Staked tokens can be unstaked at any time, and rewards can be claimed without unstaking.

## Features
- Stake tokens to earn rewards.
- Unstake tokens.
- Claim rewards without unstaking.
- Dynamic calculation of reward rates based on token balances.

## Getting Started

### Prerequisites
- Solidity compiler version 0.8.19.
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) library for ERC-20 token interfaces.
- [forge-std](https://github.com/surejam/forge-std) library for console functionality.
- [ReentrancyGuard](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol) from OpenZeppelin for protection against reentrancy attacks.

### Installation
1. Install the necessary dependencies, including OpenZeppelin and forge-std.
2. Compile the Solidity code using the Solidity compiler version 0.8.19.
3. Deploy the contract to an EVM-compatible blockchain.

## Usage

### Constructor
- `constructor(address _stakingToken, address _rewardToken)`: Initializes the contract with addresses of the staking and reward tokens.

### Staking
- `stake(uint256 amountToStake)`: Stake a specified amount of staking tokens to earn rewards.

### Unstaking
- `unstake(uint256 amountToUnstake)`: Unstake a specified amount of staking tokens and claim rewards.

### Claiming Rewards
- `claim()`: Claim rewards without unstaking.

### View Functions
- `getRewardOf(address user)`: Get the pending rewards for a specific user.

## Error Handling
The contract includes custom error messages to provide clarity in case of failures during stake, unstake, and claim operations.

## Author
- **surejam**

Feel free to contribute, report issues, or suggest improvements. Happy staking!

