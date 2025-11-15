// auction_factory.test.js
const { ethers, deployments } = require("hardhat");

describe("质押系统测试", function () {
    it("质押系统测试流程", async function () {
        await main();
    });
});

async function main() {

    console.log("🚀 开始测试质押系统...");

     // 获取测试账户
    const [signer] = await ethers.getSigners();
    console.log("   👤 部署者/调用方:", signer.address);

    // 获取meme代理合约和实现合约信息
    const proxyDeployment = await deployments.get("MetanodeStakeContractProxy");
    const implDeployment = await deployments.get("metanodeStakeContractImplementation");
    

    // 创建代理合约实例（用于直接测试）
    const metanodeStakeContractProxy = await ethers.getContractAt("MetanodeStakeContract", proxyDeployment.address);

    const tokenAddress = "0x33056bb3cDA057a11E82671dAa3C61F82c1BE20c";

    console.log("👤 调用方地址:", signer.address);
    console.log("📄 代理合约地址:", proxyDeployment.address);
    console.log("   🔧 实现合约地址:", implDeployment.address);
    console.log("🪙 TS代币地址:", tokenAddress);
    // 创建 ERC20 代币合约实例
    const tsToken = await ethers.getContractAt("IERC20", tokenAddress, signer);
    
    // 1. 获取调用方 TS 代币余额
    const userBalance = await tsToken.balanceOf(signer.address);
    console.log("💰 质押前调用方 TS 代币余额:", ethers.formatEther(userBalance), "TS");

    // 2. 获取当前合约 TS 代币余额
    const contractBalance = await tsToken.balanceOf(proxyDeployment.address);
    console.log("🏦 质押前合约 TS 代币余额:", ethers.formatEther(contractBalance), "TS");


    // 授权 1000 TS 代币
    const tx = await tsToken.approve(proxyDeployment.address, ethers.parseEther("1000"));
    await tx.wait();    
        
    console.log("✅ 成功授权 1000 TS 代币给质押合约");
        
    // 验证授权
    const allowance = await tsToken.allowance(signer.address, proxyDeployment.address);
    console.log("当前授权额度:", ethers.formatEther(allowance), "TS");


    //调用参与质押函数
    const stakeTx = await metanodeStakeContractProxy.connect(signer).participatePledge(1,ethers.parseEther("200"));
    // 等待交易确认
    const receipt = await stakeTx.wait();
    console.log("✅ 质押交易已确认，区块:", receipt.blockNumber);


    // 检查池信息
    const poolInfo = await metanodeStakeContractProxy.pools(1);
    console.log("🏊 池1信息:");
    console.log("   - 代币地址:", poolInfo.stTokenAddress);
    console.log("   - 最小质押金额:", poolInfo.minDepositAmount.toString());
    console.log("   - 总质押量:", poolInfo.stTokenAmount.toString());

    

    // 1. 获取调用方 TS 代币余额
    const userBalanceAfter = await tsToken.balanceOf(signer.address);
    console.log("💰 质押后调用方 TS 代币余额:", ethers.formatEther(userBalanceAfter), "TS");

    // 2. 获取当前合约 TS 代币余额
    const contractBalanceAfter = await tsToken.balanceOf(proxyDeployment.address);
    console.log("🏦 质押后合约 TS 代币余额:", ethers.formatEther(contractBalanceAfter), "TS");
}