# ✅ VE-Governance Protocol  
*A Vote-Escrow Based DeFi Governance & Incentive System*

---

## 📌 Overview

VE-Governance Protocol is a decentralized governance and incentive system inspired by Curve-style vote escrow mechanisms.

Users lock governance tokens to obtain voting power (veGOV), vote on liquidity gauges, earn bribes, and receive protocol rewards. The system aligns long-term commitment with governance influence and financial incentives.

This project was built as part of a college blockchain hackathon.

---

## 🚀 Key Features

- ✅ Governance Token (GOV)
- ✅ Vote Escrow (veGOV) locking mechanism
- ✅ Gauge-based voting system
- ✅ Bribe marketplace for incentives
- ✅ Liquidity staking and rewards
- ✅ Time-weighted voting power
- ✅ Fully automated demo script

---

## 🏗️ System Architecture

### 🪙 GovernanceToken.sol
An ERC20-compliant token used for governance participation and protocol incentives.  
It serves as the primary utility token for voting, staking, and earning rewards.

### 🔒 VotingEscrow.sol
Handles the locking of GOV tokens and generates veGOV voting power.  
The longer the lock duration, the higher the voting influence granted to users.

### ⚙️ GaugeController.sol
Manages the creation, configuration, and governance of liquidity gauges.  
Allows veGOV holders to vote on reward distribution across different pools.

### 💸 BribeMarket.sol
Enables external protocols and projects to offer incentives (bribes) to veGOV holders.  
Encourages voters to direct emissions toward specific liquidity pools.

### 📊 LiquidityGauge.sol
Controls liquidity provider staking and reward distribution mechanisms.  
Tracks deposits, calculates rewards, and ensures fair incentive allocation.









## 🔄 Flow

1. Users lock GOV in VotingEscrow  
2. Receive veGOV voting power  
3. Vote on gauges  
4. Protocols post bribes  
5. Users earn rewards  
6. Liquidity providers stake and earn incentives  

---

## 🛠️ Tech Stack

- Solidity ^0.8.20  
- Hardhat  
- Ethers.js  
- Node.js  
- JavaScript  
- Ethereum (Local Network)

  ## ⚙️ Installation & Setup Guide

Follow the steps below to set up and run the project locally.

---

### 2️⃣ Install Dependencies

Install all required project dependencies using npm:
```bash
npm install
```
## 3️⃣ Start Local Blockchain
Run a local Ethereum development network using Hardhat:
```bash
npx hardhat node
```

This will start a local blockchain and provide test accounts with pre-funded ETH.

##  4️⃣ Deploy Smart Contracts

Deploy the smart contracts to the local network:
```bash
npx hardhat run scripts/deploy.js --network localhost
```

After deployment, note down the generated contract addresses.

## 5️⃣ Configure Demo Script

Open the demo script file:
```bash
scripts/demo.js
```


## Paste the deployed contract addresses into the following variables:
```bash
const GOV_ADDRESS = "0x...";
const VOTING_ESCROW_ADDRESS = "0x...";
const GAUGE_CONTROLLER_ADDRESS = "0x...";
const BRIBE_MARKET_ADDRESS = "0x...";
const LIQUIDITY_GAUGE_ADDRESS = "0x...";
```

Make sure all addresses match the deployed contracts.

## 6️⃣ Run Demo

Execute the demo script to test the complete workflow:
```bash
npx hardhat run scripts/demo.js --network localhost
```
This will simulate token locking, voting, staking, and reward distribution.




## 📈 Future Improvements

### 🌐 Web Frontend
Develop a user-friendly web interface to allow users to easily lock tokens, vote on gauges, track rewards, and manage their governance participation without relying on command-line tools.

### 🔗 Cross-Chain Support
Enable interoperability across multiple blockchain networks, allowing users to participate in governance and liquidity incentives beyond a single chain.

### 🗳️ Governance Proposals
Introduce a structured proposal system where veGOV holders can submit, discuss, and vote on protocol upgrades, parameter changes, and ecosystem initiatives.

### 🖼️ NFT Voting
Implement NFT-based voting rights, where governance power can be represented through transferable or soulbound NFTs to improve transparency and engagement.

### 💰 Treasury Module
Create a dedicated treasury management system to handle protocol funds, optimize spending, and support long-term sustainability through community-approved allocations.

### 🚀 Mainnet Deployment
Deploy the protocol on Ethereum mainnet after thorough testing, ensuring scalability, reliability, and readiness for real-world usage.

### 🔐 Security Audits
Conduct professional smart contract audits and continuous security testing to identify vulnerabilities and protect user funds and protocol integrity.



veGOV-Protocol/
│
├── contracts/
│   ├── GovernanceToken.sol
│   ├── VotingEscrow.sol
│   ├── GaugeController.sol
│   ├── BribeMarket.sol
│   └── LiquidityGauge.sol
│
├── scripts/
│   ├── deploy.js
│   └── demo.js
│
├── test/
│   └── protocol.test.js
│
├── hardhat.config.js
├── package.json
└── README.md

