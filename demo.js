const { ethers } = require("hardhat");

const GOV_ADDRESS = "0x851356ae760d987E095750cCeb3bC6014560891C";
const VOTING_ESCROW_ADDRESS = "0xf5059a5D33d5853360D16C683c16e67980206f36";
const GAUGE_CONTROLLER_ADDRESS = "0x95401dc811bb5740090279Ba06cfA8fcF6113778";
const BRIBE_MARKET_ADDRESS = "0x998abeb3E57409262aE5b751f60747921B33613E";
const LIQUIDITY_GAUGE_ADDRESS = "0x4826533B4897376654Bb4d4AD88B7faFD0C98528";

const ONE_DAY = 24 * 60 * 60;

async function main() {
    const [owner, alice] = await ethers.getSigners();
    console.log("👤 Owner:", owner.address);
    console.log("👩 Alice:", alice.address);

    // Load contracts
    const gov = await ethers.getContractAt("GovernanceToken", GOV_ADDRESS);
    const votingEscrow = await ethers.getContractAt("VotingEscrow", VOTING_ESCROW_ADDRESS);
    const gaugeController = await ethers.getContractAt("GaugeController", GAUGE_CONTROLLER_ADDRESS);
    const bribeMarket = await ethers.getContractAt("BribeMarket", BRIBE_MARKET_ADDRESS);
    const liquidityGauge = await ethers.getContractAt("LiquidityGauge", LIQUIDITY_GAUGE_ADDRESS);

    // Step 1: Mint tokens to owner
    console.log("\n1️⃣ Minting GOV to owner...");
    try {
        await gov.mint(owner.address, ethers.utils.parseEther("10000"));
        console.log("✅ Minted 10,000 GOV");
    } catch (e) {
        console.log("⚠️ Mint failed:", e.message);
    }

    // Check owner balance
    const ownerBal = await gov.balanceOf(owner.address);
    console.log("Owner balance:", ethers.utils.formatEther(ownerBal));

    // Step 2: Fund Alice
    console.log("\n2️⃣ Funding Alice...");
    try {
        await gov.transfer(alice.address, ethers.utils.parseEther("1000"));
        console.log("✅ Funded Alice 1000 GOV");
    } catch (e) {
        console.log("❌ Transfer failed:", e.message);
    }

    // Step 3: Approvals
    console.log("\n3️⃣ Setting approvals...");
    try {
        await gov.connect(alice).approve(votingEscrow.address, ethers.utils.parseEther("1000"));
        console.log("✅ Approved votingEscrow");

        await gov.connect(alice).approve(liquidityGauge.address, ethers.utils.parseEther("1000"));
        console.log("✅ Approved liquidityGauge");

        await gov.connect(owner).approve(bribeMarket.address, ethers.utils.parseEther("1000"));
        console.log("✅ Approved bribeMarket");
    } catch (e) {
        console.log("❌ Approval failed:", e.message);
    }

    // Step 4: Check VotingEscrow functions
    console.log("\n4️⃣ Checking VotingEscrow functions...");
    // Let's see what functions are available
    const functions = Object.keys(votingEscrow.interface.functions);
    console.log("Available functions:", functions.filter(f => f.includes("lock") || f.includes("balance")));

    // Try different lock functions
    try {
        console.log("Trying to lock tokens...");
        // Check if createLock exists
        const tx = await votingEscrow.connect(alice).createLock(
            ethers.utils.parseEther("500"),
            30 * ONE_DAY
        );
        await tx.wait();
        console.log("✅ Lock created");

        // Wait for lock to be active
        await ethers.provider.send("evm_increaseTime", [ONE_DAY]);
        await ethers.provider.send("evm_mine", []);

        // Try to get locked balance - check what function exists
        try {
            // Try balanceOf
            const veBalance = await votingEscrow.balanceOf(alice.address);
            console.log("veGOV balance:", ethers.utils.formatEther(veBalance));

            // Use this for voting
            console.log("\n5️⃣ Voting...");
            await gaugeController.connect(alice).vote(1, veBalance);
            console.log("✅ Voted for gauge 1");
        } catch (e) {
            console.log("❌ balanceOf failed:", e.message);
        }

    } catch (e) {
        console.log("❌ Lock failed:", e.message);
    }

    // Step 6: Post bribe
    console.log("\n6️⃣ Posting bribe...");
    try {
        await bribeMarket.postBribe(1, gov.address, ethers.utils.parseEther("100"));
        console.log("✅ Bribe posted");
    } catch (e) {
        console.log("❌ Post bribe failed:", e.message);
    }

    // Step 7: Check Alice balance before claim
    console.log("\n7️⃣ Checking Alice balance...");
    try {
        const aliceBal = await gov.balanceOf(alice.address);
        console.log("Alice GOV balance:", ethers.utils.formatEther(aliceBal));
    } catch (e) {
        console.log("❌ Balance check failed:", e.message);
    }

    // Step 8: Claim bribe
    console.log("\n8️⃣ Claiming bribe...");
    try {
        await bribeMarket.connect(alice).claimBribe(1);
        console.log("✅ Bribe claim attempted");
    } catch (e) {
        console.log("❌ Claim bribe failed:", e.message);
    }

    // Step 9: Fund gauge
    console.log("\n9️⃣ Funding gauge...");
    try {
        await gov.transfer(liquidityGauge.address, ethers.utils.parseEther("200"));
        console.log("✅ Gauge funded");
    } catch (e) {
        console.log("❌ Gauge funding failed:", e.message);
    }

    // Step 10: Stake
    console.log("\n🔟 Staking...");
    try {
        await liquidityGauge.connect(alice).stake(ethers.utils.parseEther("100"));
        console.log("✅ Staked 100 GOV");
    } catch (e) {
        console.log("❌ Staking failed:", e.message);
    }

    // Step 11: Time travel
    console.log("\n⏰ Advancing time...");
    await ethers.provider.send("evm_increaseTime", [10 * ONE_DAY]);
    await ethers.provider.send("evm_mine", []);

    // Step 12: Claim rewards
    console.log("\n🏆 Claiming rewards...");
    try {
        await liquidityGauge.connect(alice).claimRewards();
        console.log("✅ Rewards claim attempted");
    } catch (e) {
        console.log("❌ Claim rewards failed:", e.message);
    }

    console.log("\n🎉 DEMO ATTEMPTED! 🎉");

    // Final balances
    console.log("\n📊 Final Balances:");
    try {
        const finalOwnerBal = await gov.balanceOf(owner.address);
        const finalAliceBal = await gov.balanceOf(alice.address);
        console.log("Owner GOV:", ethers.utils.formatEther(finalOwnerBal));
        console.log("Alice GOV:", ethers.utils.formatEther(finalAliceBal));
    } catch (e) {
        console.log("❌ Final balance check failed");
    }
}

main().catch((err) => {
    console.error("❌ Error:", err);
    process.exit(1);
});