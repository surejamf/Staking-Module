// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title StakingModule
 * @dev A smart contract for staking and earning rewards using two ERC-20 tokens.
 * @author surejam
 */

contract StakingModule is ReentrancyGuard {
    // Custom error messages
    error StakingModule__CanNotBeZero();
    error StakingModule__DepositFailed();
    error StakingModule__UnstakingFailed();
    error StakingModule__CanNotClaimZero();
    error StakingModule__ClaimFailed();
    error StakingModule__WithdrawMoreThanDeposited();
    error STakingModule__AssetNotAllowed();

    // ERC-20 token interfaces for staking and rewards tokens
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    //Constant variables
    uint256 public constant DECIMALS = 10e18;

    // Amount of rewardsToken per stakingToken since contract deployment
    uint256 public rewardPerToken;

    // Amount of rewardsToken in the contract at the last rewardPerToken refresh
    uint256 public lastRewardBalance;

    // User address to the amount of tokens staked
    mapping(address => uint256) public s_userToAmountStaked;

    // User address to starting rewardPerToken when staked
    mapping(address => uint256) public s_userToStartingRewardPerToken;

    // Event emitted when a user stakes tokens
    event TokenStaked(address indexed user, uint256 amountStaked);

    /**
     * @dev Constructor to initialize the contract with staking and reward token addresses.
     * @param _stakingToken Address of the staking token.
     * @param _rewardToken Address of the reward token.
     */
    constructor(address _stakingToken, address _rewardToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    /**
     * @dev Modifier to ensure that the provided amount is not zero.
     * @param amount The amount to check.
     */
    modifier canNotBeZero(uint256 amount) {
        if (amount == 0) {
            revert StakingModule__CanNotBeZero();
        }
        _;
    }

    /**
     * @dev Modifier to update the rewardPerToken variable based on both current and past rewards balances and the current staking token balance.
     */

    modifier updateRewardPerToken() {
        uint256 currentRewardsBalance = rewardsToken.balanceOf(address(this));
        uint256 currentStakingBalance = stakingToken.balanceOf(address(this));

        if (currentRewardsBalance == 0) {
            _;
        } else if (currentStakingBalance == 0) {
            _;
        } else {
            uint256 rewardDelta = currentRewardsBalance - lastRewardBalance;

            uint256 rewardIncrement = (rewardDelta * DECIMALS) / currentStakingBalance;

            rewardPerToken += rewardIncrement;
            lastRewardBalance = currentRewardsBalance;
            _;
        }
    }

    /**
     * @dev Stake tokens to earn rewards.
     * @param amountToStake The amount of staking tokens to stake.
     */
    function stake(uint256 amountToStake) public canNotBeZero(amountToStake) nonReentrant updateRewardPerToken {
        s_userToAmountStaked[msg.sender] += amountToStake;
        s_userToStartingRewardPerToken[msg.sender] = rewardPerToken;
        emit TokenStaked(msg.sender, amountToStake);

        bool success = stakingToken.transferFrom(msg.sender, address(this), amountToStake);
        if (!success) {
            revert StakingModule__DepositFailed();
        }
    }

    /**
     * @dev Unstake tokens and claim rewards from the staking contract.
     * @param amountToUnstake The amount of staking tokens to unstake.
     */
    function unstake(uint256 amountToUnstake) public canNotBeZero(amountToUnstake) nonReentrant updateRewardPerToken {
        if (amountToUnstake > s_userToAmountStaked[msg.sender]) {
            revert StakingModule__WithdrawMoreThanDeposited();
        }

        s_userToAmountStaked[msg.sender] -= amountToUnstake;

        bool success = IERC20(stakingToken).transfer(msg.sender, amountToUnstake);
        if (!success) {
            revert StakingModule__UnstakingFailed();
        }
    }

    /**
     * @dev Claim rewards without unstaking.
     */
    function claim() public nonReentrant updateRewardPerToken {
        uint256 amountToClaim = getRewardOf(msg.sender);

        if (amountToClaim == 0) {
            revert StakingModule__CanNotClaimZero();
        }

        s_userToStartingRewardPerToken[msg.sender] = rewardPerToken;

        bool success = IERC20(rewardsToken).transfer(msg.sender, amountToClaim);
        if (!success) {
            revert StakingModule__ClaimFailed();
        }
    }

    /**
     * @dev Get the pending rewards for a user.
     * @param user The user's address.
     * @return The amount of pending rewards.
     */
    function getRewardOf(address user) public view returns (uint256) {
        uint256 userStartingRewardRate = s_userToStartingRewardPerToken[user];
        uint256 userRewardPerToken = rewardPerToken - userStartingRewardRate;
        return userRewardPerToken * s_userToAmountStaked[user] / DECIMALS;
    }
}
