const { ethers, deployments, upgrades } = require("hardhat");
// hardhat 是 hardhat run environment，有所有的模块
const { expect } = require("chai");

describe("Test upgrade", async function () {
    it("Should be able to deploy", async function () {
        const [signer, buyer] = await ethers.getSigners()

        // 1. 部署业务合约
        await deployments.fixture(["deployNftAuction"]);

        const nftAuctionProxy = await deployments.get("NftAuctionProxy");
        console.log(nftAuctionProxy)


        // 2. 调用 createAuction 方法创建拍卖
        const nftAuction = await ethers.getContractAt(
            "NftAuction",
            nftAuctionProxy.address
        );

        await nftAuction.createAuction(
            100 * 1000,
            ethers.parseEther("0.01"),
            ethers.ZeroAddress,
            1
        );

        const auction = await nftAuction.auctions(0);
        console.log("创建拍卖成功：：", auction);

        const implAddress1 = await upgrades.erc1967.getImplementationAddress(
            nftAuctionProxy.address
        );
        // 3. 升级合约
        await deployments.fixture(["upgradeNftAuction"]);

        const implAddress2 = await upgrades.erc1967.getImplementationAddress(
            nftAuctionProxy.address
        );
        // 4. 读取合约的 auction[0]
        const auction2 = await nftAuction.auctions(0);
        console.log("升级后读取拍卖成功：：", auction2);

        console.log("implAddress1::", implAddress1, "\nimplAddress2::", implAddress2);

        const nftAuctionV2 = await ethers.getContractAt(
            "NftAuctionV2",
            nftAuctionProxy.address
        );
        const hello = await nftAuctionV2.testHello()
        console.log("hello::", hello);

        // console.log("创建拍卖成功：：", await nftAuction.auctions(0));
        expect(auction2.startTime).to.equal(auction.startTime);
    });
});