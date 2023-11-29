// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StakingModule} from "../src/StakingModule.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockFailedTransfer} from "./mocks/MockFailedTransfer.sol";
import {MockFailedTransferFrom} from "./mocks/MockFailedTransferFrom.sol";

/**
 * @title StakingModuleTest
 * @dev A test suite for the StakingModule contract.
 */
contract StakingModuleTest is Test {
    StakingModule public stakingModule;

    address public stakingToken;
    address public rewardsToken;

    address public user = address(1);

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant STARTING_REWARDS_BALANCE = 1 ether;
    uint256 public constant AMOUNT_COLLATERAL = 5 ether;

    /**
     * @dev Sets up the initial state for the tests.
     */
    function setUp() public {
        ERC20Mock stakingTokenMock = new ERC20Mock();
        ERC20Mock rewardsTokenMock = new ERC20Mock();
        stakingToken = address(stakingTokenMock);
        rewardsToken = address(rewardsTokenMock);
        stakingModule = new StakingModule(stakingToken, rewardsToken);
        ERC20Mock(stakingToken).mint(user, STARTING_USER_BALANCE);
    }

    modifier fundRewards() {
        ERC20Mock(rewardsToken).mint(address(stakingModule), STARTING_REWARDS_BALANCE);
        _;
    }

    modifier stakeTokens() {
        vm.startPrank(user);
        ERC20Mock(stakingToken).approve(address(stakingModule), AMOUNT_COLLATERAL);
        stakingModule.stake(AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    //////////////////////
    /// Stake Function ///
    //////////////////////

    /**
     * @dev Tests that a user can stake tokens successfully.
     */
    function testUserCanStake() public stakeTokens {
        uint256 actualStakingBalance = stakingModule.s_userToAmountStaked(user);
        assertEq(actualStakingBalance, AMOUNT_COLLATERAL);
    }

    /**
     * @dev Tests that a user cannot stake zero tokens.
     */
    function testUserCannotStakeZeroTokens() public {
        vm.startPrank(user);
        vm.expectRevert(StakingModule.StakingModule__CanNotBeZero.selector);
        stakingModule.stake(0);
        vm.stopPrank();
    }

    /**
     * @dev Tests that the starting reward per token is allocated correctly when staking.
     */
    function testStartingRewardPerTokenAllocated() public stakeTokens {
        uint256 expectedStartingReward = stakingModule.rewardPerToken();
        assertEq(expectedStartingReward, stakingModule.s_userToStartingRewardPerToken(user));
    }

    /**
     * @dev Tests that rewards are allocated correctly when staking.
     */
    function testRewardsAllocatedOnStake() public stakeTokens {
        uint256 expectedReward = stakingModule.rewardPerToken() * AMOUNT_COLLATERAL;
        uint256 actualReward = stakingModule.getRewardOf(user);
        assertEq(expectedReward, actualReward);
    }

    /**
     * @dev Tests that the contract reverts if the stake fails.
     */
    function testRevertsIfStakeFails() public {
        address owner = msg.sender;
        vm.startPrank(owner);
        MockFailedTransferFrom mockStakingToken = new MockFailedTransferFrom();
        StakingModule mockStakingModule = new StakingModule(address(mockStakingToken), rewardsToken);

        MockFailedTransferFrom(mockStakingToken).mint(user, AMOUNT_COLLATERAL);
        vm.stopPrank();

        vm.startPrank(user);
        MockFailedTransferFrom(mockStakingToken).approve(address(mockStakingModule), AMOUNT_COLLATERAL);
        vm.expectRevert(StakingModule.StakingModule__DepositFailed.selector);
        mockStakingModule.stake(AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    ////////////////////////
    /// Unstake Function ///
    ////////////////////////

    /**
     * @dev Tests that a user cannot unstake zero tokens.
     */
    function testCanNotUnstakeZero() public {
        vm.startPrank(user);
        vm.expectRevert(StakingModule.StakingModule__CanNotBeZero.selector);
        stakingModule.unstake(0);
        vm.stopPrank();
    }

    /**
     * @dev Tests that a user cannot unstake more tokens than they have staked.
     */
    function testCanNotUnstakeMoreThanStaked() public {
        uint256 amountToUnstake = 1 ether;
        vm.startPrank(user);
        vm.expectRevert(StakingModule.StakingModule__WithdrawMoreThanDeposited.selector);
        stakingModule.unstake(amountToUnstake);
        vm.stopPrank();
    }

    /**
     * @dev Tests that the correct amount is unstaked.
     */
    function testAmountUnstakedIsCorrect() public fundRewards stakeTokens {
        vm.startPrank(user);
        uint256 initialAmountStaked = stakingModule.s_userToAmountStaked(user);
        stakingModule.unstake(AMOUNT_COLLATERAL);
        uint256 afterUnstakingAmountStaked = stakingModule.s_userToAmountStaked(user);
        assertEq(initialAmountStaked - AMOUNT_COLLATERAL, afterUnstakingAmountStaked);
        vm.stopPrank();
    }

    /**
     * @dev Tests that the contract reverts if the unstake fails.
     */
    function testRevertsIfUnstakeFails() public {
        address owner = msg.sender;
        vm.startPrank(owner);
        MockFailedTransfer mockStakingToken = new MockFailedTransfer();
        StakingModule mockStakingModule = new StakingModule(address(mockStakingToken), rewardsToken);

        MockFailedTransfer(mockStakingToken).mint(user, AMOUNT_COLLATERAL);
        vm.stopPrank();

        vm.startPrank(user);
        MockFailedTransfer(mockStakingToken).approve(address(mockStakingModule), AMOUNT_COLLATERAL);
        mockStakingModule.stake(AMOUNT_COLLATERAL);

        vm.expectRevert(StakingModule.StakingModule__UnstakingFailed.selector);
        mockStakingModule.unstake(AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    //////////////////////
    /// Claim Function ///
    //////////////////////

    /**
     * @dev Tests that a user cannot claim rewards if they have none.
     */
    function testCanNotClaimIfRewardsAreZero() public {
        vm.startPrank(user);
        vm.expectRevert(StakingModule.StakingModule__CanNotClaimZero.selector);
        stakingModule.claim();
        vm.stopPrank();
    }

    /**
     * @dev Tests that a user can successfully claim rewards.
     */
    function testUserCanClaimRewards() public fundRewards stakeTokens {
        vm.prank(user);
        stakingModule.claim();
        uint256 finalRewardsBalance = ERC20Mock(rewardsToken).balanceOf(user);
        assertEq(finalRewardsBalance, STARTING_REWARDS_BALANCE);
    }

    /**
     * @dev Tests that the contract reverts if the claim fails.
     */
    function testRevertsIfClaimFails() public {
        address owner = msg.sender;
        vm.startPrank(owner);
        MockFailedTransfer mockRewardsToken = new MockFailedTransfer();
        StakingModule mockStakingModule = new StakingModule(stakingToken, address(mockRewardsToken));

        MockFailedTransfer(mockRewardsToken).mint(address(mockStakingModule), STARTING_REWARDS_BALANCE);
        vm.stopPrank();

        vm.startPrank(user);
        ERC20Mock(stakingToken).approve(address(mockStakingModule), AMOUNT_COLLATERAL);
        mockStakingModule.stake(AMOUNT_COLLATERAL);

        vm.expectRevert(StakingModule.StakingModule__ClaimFailed.selector);
        mockStakingModule.claim();
        vm.stopPrank();
    }

    /**
     * @dev Tests that the user's starting reward per token is updated after claiming rewards.
     */
    function testUserStartingRewardPerTokenUpdatedAfterClaim() public fundRewards stakeTokens {
        uint256 initialRewardPerToken = stakingModule.s_userToStartingRewardPerToken(user);
        vm.prank(user);
        stakingModule.claim();
        uint256 updatedRewardPerToken = stakingModule.s_userToStartingRewardPerToken(user);
        assert(initialRewardPerToken < updatedRewardPerToken);
    }

    /**
     * @dev Tests that the user's starting reward per token is refreshed correctly after multiple claims.
     */
    function testUserRewardPerTokenOfUserRefreshCorrectlyAfterMultipleClaims() public fundRewards stakeTokens {
        uint256 initialUserRewardPerToken = stakingModule.s_userToStartingRewardPerToken(user);

        vm.prank(user);
        stakingModule.claim();
        uint256 updatedUserRewardPerTokenFirstClaim = stakingModule.s_userToStartingRewardPerToken(user);

        ERC20Mock(rewardsToken).mint(address(stakingModule), STARTING_REWARDS_BALANCE);
        vm.prank(user);
        stakingModule.claim();
        uint256 updatedUserRewardPerTokenSecondClaim = stakingModule.s_userToStartingRewardPerToken(user);

        assert(initialUserRewardPerToken < updatedUserRewardPerTokenFirstClaim);
        assert(updatedUserRewardPerTokenFirstClaim == updatedUserRewardPerTokenSecondClaim);
        assertEq(updatedUserRewardPerTokenSecondClaim, stakingModule.rewardPerToken());
    }
}
