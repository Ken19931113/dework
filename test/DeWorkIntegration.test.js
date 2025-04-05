const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseUnits } = ethers.utils;

describe("DeWork 整合測試", function () {
  let owner, tenant, landlord;
  let mockUSDC, aaveProvider, interestManager, rentalNFT;
  let worldIDVerifier, selfProtocol, rentalDeposit;
  let hashKeyVerifier, noditManager, ensManager;

  const depositAmount = parseUnits("1000", 6); // 1000 USDC
  const leaseDuration = 60 * 60 * 24 * 30; // 30天

  beforeEach(async function () {
    // 獲取測試帳戶
    [owner, tenant, landlord] = await ethers.getSigners();

    // 部署模擬USDC
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    mockUSDC = await MockERC20.deploy("USDC", "USDC", 6);
    await mockUSDC.deployed();

    // 為測試帳戶鑄造USDC
    await mockUSDC.mint(owner.address, parseUnits("100000", 6));
    await mockUSDC.mint(tenant.address, parseUnits("10000", 6));
    await mockUSDC.mint(landlord.address, parseUnits("10000", 6));

    // 部署Aave收益提供者
    const AaveYieldProvider = await ethers.getContractFactory("AaveYieldProvider");
    aaveProvider = await AaveYieldProvider.deploy(mockUSDC.address);
    await aaveProvider.deployed();

    // 部署利息管理器
    const InterestManager = await ethers.getContractFactory("InterestManager");
    interestManager = await InterestManager.deploy(mockUSDC.address, aaveProvider.address);
    await interestManager.deployed();

    // 部署租賃NFT
    const RentalNFT = await ethers.getContractFactory("RentalNFT");
    rentalNFT = await RentalNFT.deploy("DeWork Rental NFT", "RENT", "https://dework.io/metadata/");
    await rentalNFT.deployed();

    // 部署World ID驗證器
    const WorldIDVerifier = await ethers.getContractFactory("WorldIDVerifier");
    worldIDVerifier = await WorldIDVerifier.deploy(
      ethers.constants.AddressZero, // 模擬地址
      1, // 群組ID
      1  // 應用ID
    );
    await worldIDVerifier.deployed();

    // 部署Self Protocol模擬合約
    const SelfProtocolMock = await ethers.getContractFactory("SelfProtocolMock");
    selfProtocol = await SelfProtocolMock.deploy();
    await selfProtocol.deployed();

    // 部署租賃押金合約
    const RentalDeposit = await ethers.getContractFactory("RentalDeposit");
    rentalDeposit = await RentalDeposit.deploy(
      mockUSDC.address,
      interestManager.address,
      rentalNFT.address,
      worldIDVerifier.address,
      selfProtocol.address
    );
    await rentalDeposit.deployed();

    // 部署HashKey身份驗證器
    const HashKeyIdentityVerifier = await ethers.getContractFactory("HashKeyIdentityVerifier");
    hashKeyVerifier = await HashKeyIdentityVerifier.deploy();
    await hashKeyVerifier.deployed();

    // 部署Nodit管理器
    const NoditManager = await ethers.getContractFactory("NoditManager");
    noditManager = await NoditManager.deploy(rentalDeposit.address, owner.address);
    await noditManager.deployed();

    // 部署ENS管理器
    const ENSManager = await ethers.getContractFactory("ENSManager");
    ensManager = await ENSManager.deploy(
      rentalNFT.address,
      ethers.constants.AddressZero, // 模擬ENS註冊表
      ethers.constants.AddressZero, // 模擬ENS解析器
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("dework.eth"))
    );
    await ensManager.deployed();

    // 設置權限
    await rentalNFT.addMinter(rentalDeposit.address);
    
    // 設置World ID驗證
    await rentalDeposit.setWorldIDRequired(false); // 測試時不要求驗證
    
    // 將租戶驗證為有效身份
    await hashKeyVerifier.verifyIdentity(
      tenant.address, 
      0, // TENANT
      80  // 初始信譽分數
    );
    
    // 將房東驗證為有效身份
    await hashKeyVerifier.verifyIdentity(
      landlord.address,
      1, // LANDLORD
      90  // 初始信譽分數
    );
  });

  it("應該可以創建租賃合約並鑄造NFT", async function () {
    // 租客批准USDC轉移
    await mockUSDC.connect(tenant).approve(rentalDeposit.address, depositAmount);

    // 創建租賃
    const tx = await rentalDeposit.connect(tenant).createRental(
      landlord.address,
      depositAmount,
      leaseDuration,
      "ipfs://QmTest",
      30 // 30% 利息分享
    );

    const receipt = await tx.wait();
    const event = receipt.events.find(e => e.event === "RentalCreated");
    expect(event).to.not.be.undefined;

    const rentalId = event.args.rentalId;
    
    // 驗證租賃信息
    const rentalInfo = await rentalDeposit.getRentalDetails(rentalId);
    expect(rentalInfo.tenant).to.equal(tenant.address);
    expect(rentalInfo.landlord).to.equal(landlord.address);
    expect(rentalInfo.depositAmount).to.equal(depositAmount);
    expect(rentalInfo.isActive).to.be.true;
    
    // 驗證NFT所有權
    const nftOwner = await rentalNFT.ownerOf(rentalId);
    expect(nftOwner).to.equal(tenant.address);
    
    // 驗證NFT元數據
    const metadata = await rentalNFT.getRentalMetadata(rentalId);
    expect(metadata.tenant).to.equal(tenant.address);
    expect(metadata.landlord).to.equal(landlord.address);
  });

  it("應該可以解決爭議並退還押金", async function () {
    // 租客批准USDC轉移
    await mockUSDC.connect(tenant).approve(rentalDeposit.address, depositAmount);

    // 創建租賃
    const tx = await rentalDeposit.connect(tenant).createRental(
      landlord.address,
      depositAmount,
      leaseDuration,
      "ipfs://QmTest",
      30 // 30% 利息分享
    );

    const receipt = await tx.wait();
    const event = receipt.events.find(e => e.event === "RentalCreated");
    const rentalId = event.args.rentalId;
    
    // 租客提出爭議
    await rentalDeposit.connect(tenant).raiseDispute(rentalId);
    
    // 平台解決爭議，有利於租客
    const tenantBalanceBefore = await mockUSDC.balanceOf(tenant.address);
    
    await rentalDeposit.connect(owner).resolveDispute(rentalId, true);
    
    const tenantBalanceAfter = await mockUSDC.balanceOf(tenant.address);
    
    // 驗證押金已退還給租客
    expect(tenantBalanceAfter.sub(tenantBalanceBefore)).to.be.closeTo(
      depositAmount,
      parseUnits("1", 6) // 允許1 USDC的誤差
    );
    
    // 驗證租賃已結束
    const rentalInfo = await rentalDeposit.getRentalDetails(rentalId);
    expect(rentalInfo.isActive).to.be.false;
    
    // 驗證NFT已燒毀
    await expect(rentalNFT.ownerOf(rentalId)).to.be.revertedWith("ERC721: invalid token ID");
  });

  it("應該可以透過Nodit執行排程任務", async function () {
    // 租客批准USDC轉移
    await mockUSDC.connect(tenant).approve(rentalDeposit.address, depositAmount);

    // 創建租賃
    const tx = await rentalDeposit.connect(tenant).createRental(
      landlord.address,
      depositAmount,
      leaseDuration,
      "ipfs://QmTest",
      30 // 30% 利息分享
    );

    const receipt = await tx.wait();
    const event = receipt.events.find(e => e.event === "RentalCreated");
    const rentalId = event.args.rentalId;
    
    // 安排租賃到期檢查任務
    const executeTime = Math.floor(Date.now() / 1000) + 100; // 當前時間 + 100秒
    const taskTx = await noditManager.scheduleTask(
      rentalId,
      executeTime,
      0 // RENTAL_EXPIRY_CHECK
    );
    
    const taskReceipt = await taskTx.wait();
    const taskEvent = taskReceipt.events.find(e => e.event === "TaskScheduled");
    const taskId = taskEvent.args.taskId;
    
    // 驗證任務已創建
    const task = await noditManager.getTaskInfo(taskId);
    expect(task.rentalId).to.equal(rentalId);
    expect(task.taskType).to.equal(0); // RENTAL_EXPIRY_CHECK
    expect(task.executed).to.be.false;
    
    // 模擬時間流逝
    await ethers.provider.send("evm_increaseTime", [150]); // 增加150秒
    await ethers.provider.send("evm_mine");
    
    // 執行任務
    await noditManager.executeTask(taskId);
    
    // 驗證任務已執行
    const taskAfter = await noditManager.getTaskInfo(taskId);
    expect(taskAfter.executed).to.be.true;
  });

  it("應該可以使用Self Protocol評估租客風險", async function () {
    // 為租客設置信用分數
    await selfProtocol.updateTenantCreditScore(
      tenant.address,
      850, // 信用分數
      2    // 風險類別
    );
    
    // 獲取推薦的利息分享百分比
    const sharingPercentage = await selfProtocol.calculateInterestSharingPercentage(tenant.address);
    expect(sharingPercentage).to.equal(4000); // 40%
    
    // 租客批准USDC轉移
    await mockUSDC.connect(tenant).approve(rentalDeposit.address, depositAmount);
    
    // 創建租賃，Self Protocol會限制利息分享百分比
    const tx = await rentalDeposit.connect(tenant).createRental(
      landlord.address,
      depositAmount,
      leaseDuration,
      "ipfs://QmTest",
      50 // 嘗試設置50%，但會被Self Protocol限制為40%
    );
    
    const receipt = await tx.wait();
    const event = receipt.events.find(e => e.event === "RentalCreated");
    const rentalId = event.args.rentalId;
    
    // 驗證租賃使用了Self Protocol建議的利息分享百分比
    const rentalInfo = await rentalDeposit.getRentalDetails(rentalId);
    expect(rentalInfo.interestSharingPercentage).to.equal(40);
  });
});
