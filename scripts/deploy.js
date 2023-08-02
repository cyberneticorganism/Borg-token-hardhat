// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
// import "https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";
// import "https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Factory.sol";
const uniswapSdk = require("@uniswap/v3-sdk")
const hre = require("hardhat");
const factoryContract = require("../artifacts/contracts/uniswapV3Factory.json");

async function main() {
  // const initialSupply = 10000;
  const kevsWallet = "0xd7360E1a1480476f52677265b38D9da26f808877"
  const factoryAddress = "0x1F98431c8aD98523631AE4a59f267346ea31F984"
  const wethAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
  const provider = new hre.ethers.providers.AlchemyProvider(network = "goerli", API_KEY);
  const signer = new hre.ethers.Wallet(PRIVATE_KEY, provider);
  
  const factory = await hre.ethers.Contract(factoryAddress, factoryContract.abi, signer);

  // factory.createPool()
  // const factory = uniswapSdk.UniswapV3Factory();

  
  const BorgToken = await hre.ethers.getContractFactory("Cyborg");
  const token = await BorgToken.deploy();
  await token.waitForDeployment();
  // tokenAddress = token.address();
  const poolAddress = await factory.createPool(token.target, wethAddress, 3000);
  await token.setUniswapPair(poolAddress);

  const totalSupply = await token.totalSupply()

  console.log(
    `GLDToken deployed to ${token.target} with an initialSupply ${totalSupply}`
  );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

