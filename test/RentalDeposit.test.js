const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("RentalDeposit", function () {
  let mockUSDC;
  let mockYieldProvider;
  let interestManager;
  let rentalNFT;
  let rentalDeposit;
  let owner;
  let tenant;
  let landlord;
  let addr3;
  
  const ONE_USDC = ethers.parseUnits("1", 6);
  const DEPOSIT_AMOUNT = ethers.parseUnits("1000", 6); // 1000 USDC
  const LEASE_DURATION = 30 * 24 * 60 * 60; // 30 days in seconds
  
  beforeEach(async function () {
    // 獲取測試賬戶
    [owner, tenant, landlord, addr3] = await ethers.getSigners();
    
    // 部署測試穩定幣
    const MockUSDC = await ethers.getContractFactory("MockUSDC");
    mockUSDC = await MockUSDC.deploy("USD Coin", "USDC", 6);
    
    // 為租客鑄造代幣
    await mockUSDC.mint(tenant.address, DEPOSIT_AMOUNT * 10n);
    
    // 部署模擬收益提供者
    const MockYieldProvider = await ethers.getContractFactory("MockYieldProvider");
    mockYieldProvider = await MockYieldProvider.deploy(await mockUSDC.getAddress());
    
    // 部署利息管理器
    const InterestManager = await ethers.getContractFactory("InterestManager");
    interestManager = await InterestManager.deploy(
      await mockUSDC.getAddress(),
      await mockYieldProvider.getAddress()
    );
    
    // 部署租賃NFT
    const RentalNFT = await ethers.getContractFactory("RentalNFT");
    rentalNFT = await RentalNFT.deploy(
      "DeWork Rental Agreement",
      "DWORK",
      "https://api.dework.com/metadata/"
    );
    
    // 部署租賃押金合約
    const RentalDeposit = await ethers.getContractFactory("RentalDeposit");
    rentalDeposit = await RentalDeposit.deploy(
      await mockUSDC.getAddress(),
      await interestManager.getAddress(),
      await rentalNFT.getAddress()
    );
    
    // 授予RentalDeposit鑄造NFT的權限
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    await rentalNFT.grantRole(MINTER_ROLE, await rentalDeposit.getAddress());
    
    // 租客批准RentalDeposit合約使用USDC
    await mockUSDC.connect(tenant).approve(await rentalDeposit.getAddress(), DEPOSIT_AMOUNT * 10n);
    
    // 平台批准InterestManager使用USDC
    await mockUSDC.connect(owner).approve(await interestManager.getAddress(), DEPOSIT_AMOUNT * 10n);
  });
  
  describe("基本功能", function () {
    it("應該能創建租賃關係", async function () {
      // 創建租賃
      await expect(
        rentalDeposit.connect(tenant).createRental(
          landlord.address,
          DEPOSIT_AMOUNT,
          LEASE_DURATION
        )
      ).to.emit(rentalDeposit, "RentalCreated")
        .withArgs(0, tenant.address, landlord.address, DEPOSIT_AMOUNT);
      
      // 檢查租賃信息
      const rental = await rentalDeposit.rentals(0);
      expect(rental.tenant).to.equal(tenant.address);
      expect(rental.landlord).to.equal(landlord.address);
      expect(rental.depositAmount).to.equal(DEPOSIT_AMOUNT);
      expect(rental.isActive).to.be.true;
      
      // 檢查NFT所有權
      expect(await rentalNFT.ownerOf(0)).to.equal(tenant.address);
    });
    
    it("應該能結束租賃並釋放押金", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 模擬時間流逝
      await time.increase(LEASE_DURATION + 1);
      
      // 結束租賃
      await expect(
        rentalDeposit.connect(landlord).endRental(0)
      ).to.emit(rentalDeposit, "DepositReleased");
      
      // 檢查租賃狀態
      const rental = await rentalDeposit.rentals(0);
      expect(rental.isActive).to.be.false;
      
      // 檢查押金轉移
      const landlordBalance = await mockUSDC.balanceOf(landlord.address);
      expect(landlordBalance).to.be.gt(0);
    });
    
    it("應該能提出爭議", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 提出爭議
      await expect(
        rentalDeposit.connect(tenant).raiseDispute(0)
      ).to.emit(rentalDeposit, "DisputeRaised")
        .withArgs(0, tenant.address);
      
      // 檢查爭議狀態
      const rental = await rentalDeposit.rentals(0);
      expect(rental.inDispute).to.be.true;
    });
    
    it("應該能解決爭議", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 提出爭議
      await rentalDeposit.connect(tenant).raiseDispute(0);
      
      // 解決爭議（支持租客）
      await expect(
        rentalDeposit.connect(owner).resolveDispute(0, true)
      ).to.emit(rentalDeposit, "DisputeResolved")
        .withArgs(0, true);
      
      // 檢查爭議狀態
      const rental = await rentalDeposit.rentals(0);
      expect(rental.isActive).to.be.false;
      expect(rental.inDispute).to.be.false;
      
      // 檢查押金返還
      const tenantBalance = await mockUSDC.balanceOf(tenant.address);
      expect(tenantBalance).to.be.gte(DEPOSIT_AMOUNT * 9n);
    });
    
    it("應該能提前終止租賃", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 提前終止租賃
      await expect(
        rentalDeposit.connect(landlord).terminateEarly(0)
      ).to.emit(rentalDeposit, "DepositRefunded");
      
      // 檢查租賃狀態
      const rental = await rentalDeposit.rentals(0);
      expect(rental.isActive).to.be.false;
      
      // 檢查押金返還
      const tenantBalance = await mockUSDC.balanceOf(tenant.address);
      expect(tenantBalance).to.be.gte(DEPOSIT_AMOUNT * 9n);
    });
  });
  
  describe("利息管理", function () {
    it("應該能生成並分配利息", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 設置較高的利率，便於測試
      await mockYieldProvider.setInterestRate(1000); // 10%
      
      // 模擬時間流逝（半年）
      await time.increase(180 * 24 * 60 * 60);
      
      // 手動觸發利息計算（僅測試用）
      await mockYieldProvider.simulateInterestPayment();
      
      // 結束租賃
      await time.increase(LEASE_DURATION + 1);
      await rentalDeposit.connect(landlord).endRental(0);
      
      // 檢查利息分配
      // 預期利息約為5%（半年10%的年化利率）
      // 平台收取10%的利息，房東獲得90%
      const landlordBalance = await mockUSDC.balanceOf(landlord.address);
      const expectedMinimum = DEPOSIT_AMOUNT + (DEPOSIT_AMOUNT * 5n * 90n) / (100n * 100n);
      expect(landlordBalance).to.be.gte(expectedMinimum);
    });
  });
  
  describe("邊緣案例和安全檢查", function () {
    it("應該阻止非授權用戶結束租賃", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 嘗試使用未授權帳戶結束租賃
      await expect(
        rentalDeposit.connect(addr3).endRental(0)
      ).to.be.revertedWith("Not authorized");
    });
    
    it("應該阻止在租期內結束租賃", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 嘗試在租期結束前結束租賃
      await expect(
        rentalDeposit.connect(landlord).endRental(0)
      ).to.be.revertedWith("Lease period not ended");
    });
    
    it("應該阻止房東提出爭議", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 嘗試由房東提出爭議
      await expect(
        rentalDeposit.connect(landlord).raiseDispute(0)
      ).to.be.revertedWith("Only tenant can raise dispute");
    });
    
    it("應該阻止非所有者解決爭議", async function () {
      // 創建租賃
      await rentalDeposit.connect(tenant).createRental(
        landlord.address,
        DEPOSIT_AMOUNT,
        LEASE_DURATION
      );
      
      // 提出爭議
      await rentalDeposit.connect(tenant).raiseDispute(0);
      
      // 嘗試由非所有者解決爭議
      await expect(
        rentalDeposit.connect(addr3).resolveDispute(0, true)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
