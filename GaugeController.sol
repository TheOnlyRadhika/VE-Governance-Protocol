// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVotingEscrow {
    function votingPowerOf(address user) external view returns (uint256);
}

contract GaugeController {
    IVotingEscrow public immutable votingEscrow;

    uint256 public gaugeCount;
    uint256 public totalVotes;

    // gaugeId => name
    mapping(uint256 => string) public gauges;

    // gaugeId => total votes
    mapping(uint256 => uint256) public gaugeVotes;

    // user => gaugeId => votes
    mapping(address => mapping(uint256 => uint256)) public userVotes;

    event GaugeAdded(uint256 indexed gaugeId, string name);
    event VoteCast(
        address indexed user,
        uint256 indexed gaugeId,
        uint256 weight
    );

    constructor(address _votingEscrow) {
        require(_votingEscrow != address(0), "Invalid voting escrow");
        votingEscrow = IVotingEscrow(_votingEscrow);
    }

    // ----------------------------
    // ADMIN / SETUP
    // ----------------------------

    function addGauge(string calldata name) external {
        gaugeCount++;
        gauges[gaugeCount] = name;
        emit GaugeAdded(gaugeCount, name);
    }

    // ----------------------------
    // GOVERNANCE
    // ----------------------------

    function vote(uint256 gaugeId, uint256 weight) external {
        require(gaugeId > 0 && gaugeId <= gaugeCount, "Invalid gauge");

        uint256 votingPower = votingEscrow.votingPowerOf(msg.sender);
        //require(weight <= votingPower, "Insufficient veGOV");

        uint256 previousVote = userVotes[msg.sender][gaugeId];

        if (previousVote > 0) {
            gaugeVotes[gaugeId] -= previousVote;
            totalVotes -= previousVote;
        }

        userVotes[msg.sender][gaugeId] = weight;
        gaugeVotes[gaugeId] += weight;
        totalVotes += weight;

        emit VoteCast(msg.sender, gaugeId, weight);
    }

    // ----------------------------
    // VIEW HELPERS
    // ----------------------------

    function gaugeWeight(uint256 gaugeId) external view returns (uint256) {
        if (totalVotes == 0) return 0;
        return (gaugeVotes[gaugeId] * 1e18) / totalVotes;
    }
}
