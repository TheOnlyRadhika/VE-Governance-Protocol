// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceToken is ERC20, Ownable {
    address public minter;

    event MinterSet(address indexed minter);

    constructor() ERC20("Governance Token", "GOV") Ownable(msg.sender) {
        // Initial supply for testing/liquidity
        _mint(msg.sender, 1_000_000 * 10 ** 18);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
        emit MinterSet(_minter);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Only minter");
        _mint(to, amount);
    }
}
