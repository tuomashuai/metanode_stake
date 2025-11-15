const { deployments, upgrades, ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async ({deployments}) => {
    // 获取部署管理器
    const { save, log } = deployments;
    // 获取配置文件当中的账户 
    // 获取部署者信息
    const [deployer] = await ethers.getSigners();
    console.log("部署者地址:", deployer.address);

    const balance = await ethers.provider.getBalance(deployer);
    console.log("部署者余额:",ethers.formatEther(balance) , "ETH");


    // 获取指定代币余额（例如 TS)
    const tokenAddress = "0x33056bb3cDA057a11E82671dAa3C61F82c1BE20c"; // 替换为实际的代币地址
    await getTokenBalance(deployer, tokenAddress, "TS");


    console.log("✅ 环境测试通过");
    //部署质押合约
    const metanodeStakeContract = await ethers.getContractFactory("MetanodeStakeContract");

    // 使用 OpenZeppelin Upgrades 部署 UUPS 代理合约
    // UUPS 优势：升级逻辑在实现合约中，代理合约更轻量，Gas成本更低
    const metanodeStakeContractProxy = await upgrades.deployProxy(
        metanodeStakeContract,
        [deployer.address],
        {
            initializer: "initialize",
            kind: 'uups' // 明确指定 UUPS 代理模式
        }
    );
    await metanodeStakeContractProxy.waitForDeployment();

    const proxyAddress = await metanodeStakeContractProxy.getAddress();
    const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);

    console.log("   ✅ 代理合约地址：", proxyAddress);
    console.log("   🔧 实现合约地址：", implAddress);

    // 保存代理合约信息
    await save("MetanodeStakeContractProxy", {
        abi: metanodeStakeContract.interface.format("json"),
        address: proxyAddress,
    });

    // 保存实现合约信息
    await save("metanodeStakeContractImplementation", {
        abi: metanodeStakeContract.interface.format("json"),
        address: implAddress,
    });


    // 4. 保存到本地缓存文件（可选，便于其他脚本使用）
    const storePath = path.resolve(__dirname, "./.cache/factorySystem.json");
    fs.writeFileSync(
        storePath,
        JSON.stringify({
            proxyAddress,
            implAddress,
            abi: metanodeStakeContract.interface.format("json"),
        })
    );

    

}
async function getTokenBalance(account, tokenAddress, tokenName) {
    const IERC20_ABI = [
        "function balanceOf(address) view returns (uint256)",
        "function decimals() view returns (uint8)",
        "function symbol() view returns (string)"
    ];
    
    try {
        const tokenContract = new ethers.Contract(tokenAddress, IERC20_ABI, ethers.provider);
        const [balance, decimals, symbol] = await Promise.all([
            tokenContract.balanceOf(account),
            tokenContract.decimals(),
            tokenContract.symbol()
        ]);
        
        const formattedBalance = ethers.formatEther(balance, decimals);
        console.log(`${tokenName} (${symbol}) 余额:`, formattedBalance);
        
    } catch (error) {
        console.log(`无法获取 ${tokenName} 余额:`, error.message);
    }
}

module.exports.tags = ["deployMetanodeStake"];