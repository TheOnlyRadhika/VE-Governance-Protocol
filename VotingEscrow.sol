// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VotingEscrow is ReentrancyGuard {
    IERC20 public immutable govToken;

    uint256 public constant MAX_LOCK_TIME = 4 * 365 days;

    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock) public locks;

    uint256 public totalLocked;

    event LockCreated(address indexed user, uint256 amount, uint256 unlockTime);
    event LockExtended(address indexed user, uint256 newUnlockTime);
    event AmountIncreased(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _govToken) {
        require(_govToken != address(0), "Invalid GOV token");
        govToken = IERC20(_govToken);
    }

    // ----------------------------
    // USER ACTIONS
    // ----------------------------

    function createLock(
        uint256 amount,
        uint256 lockDuration
    ) external nonReentrant {
        require(amount > 0, "Amount = 0");
        require(locks[msg.sender].amount == 0, "Lock already exists");
        require(
            lockDuration > 0 && lockDuration <= MAX_LOCK_TIME,
            "Invalid lock duration"
        );

        uint256 unlockTime = block.timestamp + lockDuration;

        locks[msg.sender] = Lock({amount: amount, unlockTime: unlockTime});

        totalLocked += amount;
        govToken.transferFrom(msg.sender, address(this), amount);

        emit LockCreated(msg.sender, amount, unlockTime);
    }

    function increaseAmount(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount = 0");

        Lock storage lock = locks[msg.sender];
        require(lock.amount > 0, "No lock");
        require(block.timestamp < lock.unlockTime, "Lock expired");

        lock.amount += amount;
        totalLocked += amount;
        govToken.transferFrom(msg.sender, address(this), amount);

        emit AmountIncreased(msg.sender, amount);
    }

    function extendLock(uint256 additionalTime) external nonReentrant {
        require(additionalTime > 0, "Invalid time");

        Lock storage lock = locks[msg.sender];
        require(lock.amount > 0, "No lock");

        uint256 newUnlockTime = lock.unlockTime + additionalTime;
        require(
            newUnlockTime <= block.timestamp + MAX_LOCK_TIME,
            "Exceeds max lock"
        );

        lock.unlockTime = newUnlockTime;

        emit LockExtended(msg.sender, newUnlockTime);
    }

    function withdraw() external nonReentrant {
        Lock memory lock = locks[msg.sender];
        require(lock.amount > 0, "Nothing locked");
        require(block.timestamp >= lock.unlockTime, "Lock not expired");

        delete locks[msg.sender];
        totalLocked -= lock.amount;

        govToken.transfer(msg.sender, lock.amount);

        emit Withdrawn(msg.sender, lock.amount);
    }

    // ----------------------------
    // GOVERNANCE POWER
    // ----------------------------

    function votingPowerOf(address user) public view returns (uint256) {
        Lock memory lock = locks[user];

        if (lock.amount == 0 || block.timestamp >= lock.unlockTime) {
            return 0;
        }

        uint256 remainingTime = lock.unlockTime - block.timestamp;

        return (lock.amount * remainingTime) / MAX_LOCK_TIME;
    }
}
