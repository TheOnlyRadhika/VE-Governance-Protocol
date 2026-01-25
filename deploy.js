const { ethers } = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();

    console.log("🚀 Deploying with account:", deployer.address);

    const balance = await deployer.getBalance();
    console.log("Balance:", ethers.utils.formatEther(balance), "ETH");

    /* -------------------- Deploy GovernmentToken -------------------- */

    const GovToken = await ethers.getContractFactory("GovernanceToken");
    const gov = await GovToken.deploy();
    await gov.deployed();

    console.log("✅ GovernmentToken deployed to:", gov.address);

    /* -------------------- Deploy VotingEscrow -------------------- */

    const VotingEscrow = await ethers.getContractFactory("VotingEscrow");
    const votingEscrow = await VotingEscrow.deploy(gov.address);
    await votingEscrow.deployed();

    console.log("✅ VotingEscrow deployed to:", votingEscrow.address);

    /* -------------------- Deploy GaugeController -------------------- */

    const GaugeController = await ethers.getContractFactory("GaugeController");
    const gaugeController = await GaugeController.deploy(votingEscrow.address);
    await gaugeController.deployed();

    console.log("✅ GaugeController deployed to:", gaugeController.address);

    /* -------------------- Deploy BribeContract -------------------- */

    const BribeContract = await ethers.getContractFactory("BribeMarket");
    const bribe = await BribeContract.deploy(gaugeController.address);
    await bribe.deployed();

    console.log("✅ BribeContract deployed to:", bribe.address);

    /* -------------------- Add Default Gauge -------------------- */

    console.log("📌 Adding initial gauge...");
    const tx = await gaugeController.addGauge("Main Gauge");
    await tx.wait();

    console.log("✅ Gauge Added");

    /* -------------------- Deploy LiquidityGauge -------------------- */

    const LiquidityGauge = await ethers.getContractFactory("LiquidityGauge");

    const liquidityGauge = await LiquidityGauge.deploy(
        gov.address,          // stake token
        gov.address,          // reward token
        votingEscrow.address, // voting escrow
        gaugeController.address,
        1
    );

    await liquidityGauge.deployed();

    console.log("✅ LiquidityGauge deployed to:", liquidityGauge.address);

    /* -------------------- Summary -------------------- */

    console.log("\n🎉 DEPLOYMENT COMPLETE 🎉\n");

    console.log("GovToken        :", gov.address);
    console.log("VotingEscrow    :", votingEscrow.address);
    console.log("GaugeController :", gaugeController.address);
    console.log("BribeContract   :", bribe.address);
    console.log("LiquidityGauge  :", liquidityGauge.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });





