import { expect } from "chai";


describe("Full DeFi Governance Flow", function () {
  let gov;
  let votingEscrow;
  let gaugeController;
  let bribeMarket;
  let liquidityGauge;

  let owner, alice;

  const ONE_DAY = 24 * 60 * 60;

  beforeEach(async function () {
    [owner, alice] = await ethers.getSigners();

    /* -------------------- Deploy GovernanceToken -------------------- */
    const GOV = await ethers.getContractFactory("GovernanceToken");
    gov = await GOV.deploy();
    await gov.waitForDeployment();

    // Give Alice GOV
    await gov.transfer(alice.address, ethers.parseEther("1000"));

    /* -------------------- Deploy VotingEscrow -------------------- */
    const VotingEscrow = await ethers.getContractFactory("VotingEscrow");
    votingEscrow = await VotingEscrow.deploy(gov.target);
    await votingEscrow.waitForDeployment();

    /* -------------------- Deploy GaugeController -------------------- */
    const GaugeController = await ethers.getContractFactory("GaugeController");
    gaugeController = await GaugeController.deploy(votingEscrow.target);
    await gaugeController.waitForDeployment();

    // Add one gauge
    await gaugeController.addGauge("Gauge #1");

    /* -------------------- Deploy BribeMarket -------------------- */
    const BribeMarket = await ethers.getContractFactory("BribeMarket");
    bribeMarket = await BribeMarket.deploy(gaugeController.target);
    await bribeMarket.waitForDeployment();

    /* -------------------- Deploy LiquidityGauge -------------------- */
    const LiquidityGauge = await ethers.getContractFactory("LiquidityGauge");
    liquidityGauge = await LiquidityGauge.deploy(
      gov.target,              // stake token
      gov.target,              // reward token
      votingEscrow.target,     // VotingEscrow
      gaugeController.target,  // GaugeController
      1                        // gaugeId
    );
    await liquidityGauge.waitForDeployment();

    /* -------------------- Approvals -------------------- */
    await gov.connect(alice).approve(votingEscrow.target, ethers.MaxUint256);
    await gov.connect(alice).approve(liquidityGauge.target, ethers.MaxUint256);
    await gov.connect(owner).approve(bribeMarket.target, ethers.MaxUint256);
    await gov.connect(owner).approve(liquidityGauge.target, ethers.MaxUint256);
  });

  it("runs full governance → bribe → boosted rewards flow", async function () {

    /* -------------------- Alice locks GOV -------------------- */
    await votingEscrow
      .connect(alice)
      .createLock(
        ethers.parseEther("500"),
        30 * ONE_DAY
      );

    const veGov = await votingEscrow.votingPowerOf(alice.address);
    expect(veGov).to.be.gt(0);

    /* -------------------- Alice votes for gauge -------------------- */
    await gaugeController
      .connect(alice)
      .vote(1, veGov);

    const weight = await gaugeController.gaugeWeight(1);
    expect(weight).to.be.gt(0);

    /* -------------------- Owner posts bribe -------------------- */
    await bribeMarket.postBribe(
      1,
      gov.target,
      ethers.parseEther("100")
    );

    /* -------------------- Alice claims bribe -------------------- */
    const bribeBefore = await gov.balanceOf(alice.address);

    await bribeMarket
      .connect(alice)
      .claimBribe(1);

    const bribeAfter = await gov.balanceOf(alice.address);

    expect(bribeAfter).to.be.gt(bribeBefore);

    /* -------------------- Fund LiquidityGauge -------------------- */
    await liquidityGauge.fundRewards(
      ethers.parseEther("200")
    );

    /* -------------------- Alice stakes GOV -------------------- */
    await liquidityGauge
      .connect(alice)
      .stake(ethers.parseEther("100"));

    /* -------------------- Time passes -------------------- */
    await ethers.provider.send("evm_increaseTime", [10 * ONE_DAY]);
    await ethers.provider.send("evm_mine", []);

    /* -------------------- Alice claims rewards -------------------- */
    const rewardsBefore = await gov.balanceOf(alice.address);

    await liquidityGauge
      .connect(alice)
      .claimRewards();

    const rewardsAfter = await gov.balanceOf(alice.address);

    expect(rewardsAfter).to.be.gt(rewardsBefore);
  });
});

