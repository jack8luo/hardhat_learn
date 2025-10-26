const {deployments, upgrades} = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();

    console.log("用户地址", deployer);
    const NftAuction = await ethers.getContractFactory("NftAuction");

    // 通过代理合约部署
    const nftAuctionProxy = await upgrades.deployProxy(NftAuction, [], {
        initializer: "initialize",
    })

    await nftAuctionProxy.waitForDeployment();
    const proxyAddress = await nftAuctionProxy.getAddress();
    console.log("代理合约地址：", proxyAddress);
    console.log("实现合约地址：", await upgrades.erc1967.getImplementationAddress(proxyAddress));

    module.exports.tags = ["deployNftAuction"]
}