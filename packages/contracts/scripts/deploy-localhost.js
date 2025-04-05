// 部署腳本 - 專門為本地網絡設計
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 強制指定為本地網絡
  const network = "localhost";
  const chainId = 31337;
  
  console.log("Deploying to localhost network (Chain ID: 31337)");

  // 部署模擬USDC代幣
  console.log("Deploying MockUSDC...");
  const MockUSDC = await ethers.getContractFactory("MockUSDC");
  const mockUSDC = await MockUSDC.deploy("USDC", "USDC", 6);
  await mockUSDC.waitForDeployment();
  const usdcAddress = await mockUSDC.getAddress();
  console.log("MockUSDC deployed to:", usdcAddress);

  // 為部署者鑄造一些測試代幣
  await mockUSDC.mint(deployer.address, ethers.utils.parseUnits("10000", 6));
  console.log("Minted 10,000 USDC for deployer");

  // 部署收益提供者 (Aave)
  console.log("Deploying AaveYieldProvider...");
  const AaveYieldProvider = await ethers.getContractFactory("AaveYieldProvider");
  const aaveProvider = await AaveYieldProvider.deploy(usdcAddress);
  await aaveProvider.waitForDeployment();
  const aaveProviderAddress = await aaveProvider.getAddress();
  console.log("AaveYieldProvider deployed to:", aaveProviderAddress);

  // 部署利息管理器
  console.log("Deploying InterestManager...");
  const InterestManager = await ethers.getContractFactory("InterestManager");
  const interestManager = await InterestManager.deploy(usdcAddress, aaveProviderAddress);
  await interestManager.waitForDeployment();
  const interestManagerAddress = await interestManager.getAddress();
  console.log("InterestManager deployed to:", interestManagerAddress);

  // 部署租賃NFT
  console.log("Deploying RentalNFT...");
  const RentalNFT = await ethers.getContractFactory("RentalNFT");
  const rentalNFT = await RentalNFT.deploy(
    "DeWork Rental NFT",
    "RENT",
    "https://dework.io/metadata/"
  );
  await rentalNFT.waitForDeployment();
  const rentalNFTAddress = await rentalNFT.getAddress();
  console.log("RentalNFT deployed to:", rentalNFTAddress);

  // 部署WorldID驗證器
  console.log("Deploying WorldIDVerifier...");
  const WorldIDVerifier = await ethers.getContractFactory("WorldIDVerifier");
  const worldIDVerifier = await WorldIDVerifier.deploy(
    "0x1100000000000000000000000000000000000001", // 模擬WorldID合約地址
    1,  // 群組ID
    1   // 應用ID
  );
  await worldIDVerifier.waitForDeployment();
  const worldIDVerifierAddress = await worldIDVerifier.getAddress();
  console.log("WorldIDVerifier deployed to:", worldIDVerifierAddress);

  // 部署Self Protocol模擬合約
  console.log("Deploying SelfProtocolMock...");
  const SelfProtocolMock = await ethers.getContractFactory("SelfProtocolMock");
  const selfProtocol = await SelfProtocolMock.deploy();
  await selfProtocol.waitForDeployment();
  const selfProtocolAddress = await selfProtocol.getAddress();
  console.log("SelfProtocolMock deployed to:", selfProtocolAddress);

  // 部署租賃押金合約
  console.log("Deploying RentalDeposit...");
  const RentalDeposit = await ethers.getContractFactory("RentalDeposit");
  const rentalDeposit = await RentalDeposit.deploy(
    usdcAddress,
    interestManagerAddress,
    rentalNFTAddress,
    worldIDVerifierAddress,
    selfProtocolAddress
  );
  await rentalDeposit.waitForDeployment();
  const rentalDepositAddress = await rentalDeposit.getAddress();
  console.log("RentalDeposit deployed to:", rentalDepositAddress);

  // 部署HashKey身份驗證器
  console.log("Deploying HashKeyIdentityVerifier...");
  const HashKeyIdentityVerifier = await ethers.getContractFactory("HashKeyIdentityVerifier");
  const hashKeyVerifier = await HashKeyIdentityVerifier.deploy();
  await hashKeyVerifier.waitForDeployment();
  const hashKeyVerifierAddress = await hashKeyVerifier.getAddress();
  console.log("HashKeyIdentityVerifier deployed to:", hashKeyVerifierAddress);

  // 部署Nodit管理器
  console.log("Deploying NoditManager...");
  const NoditManager = await ethers.getContractFactory("NoditManager");
  const noditManager = await NoditManager.deploy(
    rentalDepositAddress,
    deployer.address // 初始觸發者設為部署者
  );
  await noditManager.waitForDeployment();
  const noditManagerAddress = await noditManager.getAddress();
  console.log("NoditManager deployed to:", noditManagerAddress);

  // 部署ENS管理器
  console.log("Deploying ENSManager...");
  const ENSManager = await ethers.getContractFactory("ENSManager");
  const ensManager = await ENSManager.deploy(
    rentalNFTAddress,
    "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e", // ENS Registry (Sepolia)
    "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0", // ENS 解析器（測試用）
    "0x8fe5f93f5c292b7781c37c4501a2a258e5d57330ea1ad023de7385c159a2e693" // 子域名根結點 (keccak256('dework.eth'))
  );
  await ensManager.waitForDeployment();
  const ensManagerAddress = await ensManager.getAddress();
  console.log("ENSManager deployed to:", ensManagerAddress);

  // 設置必要的權限
  console.log("Setting up permissions...");

  // 將租賃押金合約添加為NFT鑄造者
  await rentalNFT.addMinter(rentalDepositAddress);
  console.log("Added RentalDeposit as minter for RentalNFT");

  // 保存部署信息到文件
  const deploymentInfo = {
    network,
    chainId,
    contracts: {
      USDC: usdcAddress,
      AaveYieldProvider: aaveProviderAddress,
      InterestManager: interestManagerAddress,
      RentalNFT: rentalNFTAddress,
      WorldIDVerifier: worldIDVerifierAddress,
      SelfProtocol: selfProtocolAddress,
      RentalDeposit: rentalDepositAddress,
      HashKeyIdentityVerifier: hashKeyVerifierAddress,
      NoditManager: noditManagerAddress,
      ENSManager: ensManagerAddress
    },
    timestamp: new Date().toISOString()
  };

  // 確保deploy目錄存在
  const deployDir = path.join(__dirname, "../deploy");
  if (!fs.existsSync(deployDir)) {
    fs.mkdirSync(deployDir);
  }

  // 寫入部署信息
  fs.writeFileSync(
    path.join(deployDir, `deployment-${network}.json`),
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("Deployment completed and info saved to deploy directory");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });