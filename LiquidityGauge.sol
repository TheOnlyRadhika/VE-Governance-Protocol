// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* -------------------- IMPORTS -------------------- */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/* -------------------- INTERFACES -------------------- */

// Voting Escrow (veToken)
interface IVotingEscrow {
    function votingPowerOf(address user) external view returns (uint256);
}

// Gauge Controller
interface IGaugeController {
    function gaugeWeight(uint256 gaugeId) external view returns (uint256);
}

/* -------------------- MAIN CONTRACT -------------------- */

contract LiquidityGauge is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* -------------------- STATE -------------------- */

    IERC20 public immutable stakeToken; // LP / GOV token
    IERC20 public immutable rewardToken; // Reward token

    IVotingEscrow public immutable votingEscrow;
    IGaugeController public immutable gaugeController;

    uint256 public immutable gaugeId;

    // Base reward: 1 token per second (scaled)
    uint256 public constant BASE_REWARD_RATE = 1e18;

    // Max boost = 2x
    uint256 public constant MAX_BOOST = 2e18;

    /* -------------------- USER DATA -------------------- */

    struct UserInfo {
        uint256 amount; // Staked tokens
        uint256 pending; // Pending rewards
        uint256 lastUpdate; // Last reward update
    }

    mapping(address => UserInfo) public users;

    /* -------------------- EVENTS -------------------- */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardsFunded(uint256 amount);

    /* -------------------- CONSTRUCTOR -------------------- */

    constructor(
        address _stakeToken,
        address _rewardToken,
        address _votingEscrow,
        address _gaugeController,
        uint256 _gaugeId
    ) {
        require(
            _stakeToken != address(0) &&
                _rewardToken != address(0) &&
                _votingEscrow != address(0) &&
                _gaugeController != address(0),
            "Invalid address"
        );

        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        votingEscrow = IVotingEscrow(_votingEscrow);
        gaugeController = IGaugeController(_gaugeController);
        gaugeId = _gaugeId;
    }

    /* -------------------- USER ACTIONS -------------------- */

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount = 0");

        _updateRewards(msg.sender);

        users[msg.sender].amount += amount;

        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount = 0");
        require(users[msg.sender].amount >= amount, "Insufficient balance");

        _updateRewards(msg.sender);

        users[msg.sender].amount -= amount;

        stakeToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);

        uint256 reward = users[msg.sender].pending;
        require(reward > 0, "No rewards");

        users[msg.sender].pending = 0;

        rewardToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    /* -------------------- ADMIN / FUNDING -------------------- */

    function fundRewards(uint256 amount) external {
        require(amount > 0, "Amount = 0");

        rewardToken.safeTransferFrom(msg.sender, address(this), amount);

        emit RewardsFunded(amount);
    }

    /* -------------------- INTERNAL LOGIC -------------------- */

    function _updateRewards(address user) internal {
        uint256 earned = _calculateRewards(user);

        users[user].pending += earned;
        users[user].lastUpdate = block.timestamp;
    }

    function _calculateRewards(address user) internal view returns (uint256) {
        UserInfo memory info = users[user];

        if (info.amount == 0 || info.lastUpdate == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - info.lastUpdate;

        // Base reward
        uint256 baseReward = (info.amount * BASE_REWARD_RATE * timeElapsed) /
            1e18;

        // Boosted reward
        uint256 boost = _calculateBoost(user);

        uint256 boosted = (baseReward * boost) / 1e18;

        return boosted;
    }

    function _calculateBoost(address user) internal view returns (uint256) {
        uint256 votingPower = votingEscrow.votingPowerOf(user);

        uint256 gaugeWeight = gaugeController.gaugeWeight(gaugeId);

        if (votingPower == 0 || gaugeWeight == 0) {
            return 1e18; // No boost (1x)
        }

        // 1 + (votingPower / gaugeWeight)
        uint256 boost = 1e18 + (votingPower * 1e18) / gaugeWeight;

        if (boost > MAX_BOOST) {
            return MAX_BOOST;
        }

        return boost;
    }

    /* -------------------- VIEW FUNCTIONS -------------------- */

    function balanceOf(address user) external view returns (uint256) {
        return users[user].amount;
    }

    function pendingRewards(address user) external view returns (uint256) {
        uint256 current = _calculateRewards(user);

        return users[user].pending + current;
    }

    function getBoost(address user) external view returns (uint256) {
        return _calculateBoost(user);
    }
}
