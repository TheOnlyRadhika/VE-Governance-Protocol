// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IGaugeController {
    function userVotes(
        address user,
        uint256 gaugeId
    ) external view returns (uint256);

    function gaugeVotes(uint256 gaugeId) external view returns (uint256);
}

contract BribeMarket is ReentrancyGuard {
    struct Bribe {
        IERC20 token;
        uint256 amount;
        bool claimed;
    }

    // gaugeId => bribe
    mapping(uint256 => Bribe) public bribes;

    IGaugeController public immutable gaugeController;

    event BribePosted(uint256 indexed gaugeId, address token, uint256 amount);
    event BribeClaimed(
        address indexed user,
        uint256 indexed gaugeId,
        uint256 amount
    );

    constructor(address _gaugeController) {
        require(_gaugeController != address(0), "Invalid gauge controller");
        gaugeController = IGaugeController(_gaugeController);
    }

    // ----------------------------
    // BRIBE CREATION
    // ----------------------------

    function postBribe(
        uint256 gaugeId,
        address token,
        uint256 amount
    ) external nonReentrant {
        require(amount > 0, "Amount = 0");
        require(token != address(0), "Invalid token");
        require(bribes[gaugeId].amount == 0, "Bribe already exists");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bribes[gaugeId] = Bribe({
            token: IERC20(token),
            amount: amount,
            claimed: false
        });

        emit BribePosted(gaugeId, token, amount);
    }

    // ----------------------------
    // BRIBE CLAIMING
    // ----------------------------

    function claimBribe(uint256 gaugeId) external nonReentrant {
        Bribe storage bribe = bribes[gaugeId];
        require(!bribe.claimed, "Bribe already claimed");

        uint256 userVote = gaugeController.userVotes(msg.sender, gaugeId);
        require(userVote > 0, "No vote for this gauge");

        uint256 totalGaugeVotes = gaugeController.gaugeVotes(gaugeId);
        require(totalGaugeVotes > 0, "No votes");

        uint256 payout = (bribe.amount * userVote) / totalGaugeVotes;
        require(payout > 0, "Nothing to claim");

        bribe.claimed = true;

        bribe.token.transfer(msg.sender, payout);

        emit BribeClaimed(msg.sender, gaugeId, payout);
    }
}
