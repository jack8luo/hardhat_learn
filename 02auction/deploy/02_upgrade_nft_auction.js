const {ethers, upgrades} = require("hardhat")
const path = require("path");
const fs = require("fs");

module.exports = async function({getNamedAccounts, deployments}){
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();

    console.log("部署合约地址", deployer)

    // 读取.cache/proxyNftAuction.json文件
    const storePath = path.resolve(__dirname,"./.cache/proxyNftAuction.json");
    const storeDate = fs.readFileSync(storePath,"utf-8");
    const {proxyAddress, implAddress, abi} = JSON.parse(storeDate);

    // 升级版的业务合约
    const NftAuctionV2 = await ethers.getContractFactory("NftAuctionV2")

    //升级代理合约
    const nftAuctionProxy2 = await upgrades.upgradeProxy(proxyAddress, NftAuctionV2)
    await nftAuctionProxy2.waitForDeployment()
    const proxyAddress2 = await nftAuctionProxy2.getAddress()

    await save("NftAuctionProxyV2", {
        abi:NftAuctionV2.interface.format("json"),
        address:proxyAddress2
    })


}

// todo
module.exports.tags = ["upgradeNftAuction"]