const { ethers, deployments } = require("hardhat");
const { expect } = require("chai");

/**
 * 使用 hardhat-deploy 的 fixture 机制来“按标签”跑部署脚本，
 * 然后在单个用例里完成：部署测试用 ERC721、mint、授权、创建拍卖、出价、结束拍卖、断言结果。
 */
describe("Test auction", async function () {
    it("Should be ok", async function () {
        await main(); // 将测试主流程封装到 main，便于复用
    });
});

async function main() {
    /**
     * 1) 通过 fixture 执行带有 tags=["deployNftAuction"] 的部署脚本（直接部署）
     *    - 优点：fixture 会缓存部署快照，测试回滚更快、可重复性强
     *    - 前提：你的 部署脚本 里必须 `module.exports.tags = ["deployNftAuction"]`
     */
    await deployments.fixture(["deployNftAuction"]);

    /**
     * 2) 读取部署代理：NftAuctionProxy
     *    - hardhat-deploy 会把每个 deploy(name, ...) 生成的地址/abi 写到 deployments 目录
     *    - 名称必须与部署脚本里的 `deploy("NftAuctionProxy", ...)` 完全一致
     *    * 我这里是save到./.cache/里面了
     */
    const nftAuctionProxy = await deployments.get("NftAuctionProxy");

    /**
     * 3) 用实现合约 ABI 绑定到代理地址 -- 用实现合约 NftAuction 的 ABI，在“代理地址”上创建一个可交互的合约实例
     *    - 代理合约对外地址是 proxy.address
     *    - 通过实现合约名 "NftAuction" 的 ABI 与该地址交互
     */
    const nftAuction = await ethers.getContractAt("NftAuction", nftAuctionProxy.address);

    /**
     * 4) 取两个账户：
     *    - signer：卖家 / 拍卖发起者
     *    - buyer ：买家 / 出价者
     */
    const [signer, buyer] = await ethers.getSigners();
    // nftAuctionProxy.setPriceFeed() // 如你的实现需要喂价，可在此设置

    /**
     * 5) 部署一份用于测试的 ERC721 合约（本地合约）
     *    - TestERC721 是最小实现，支持 mint
     */
    const TestERC721 = await ethers.getContractFactory("TestERC721");
    const testERC721 = await TestERC721.deploy();
    await testERC721.waitForDeployment(); // 等待部署交易被打包
    const testERC721Address = await testERC721.getAddress();
    console.log("testERC721Address::", testERC721Address);

    /**
     * 6) 给 signer 铸造 10 枚 NFT（tokenId: 1..10）
     *    - 让 signer 持有要拍卖的 NFT
     */
    for (let i = 0; i < 10; i++) {
        await testERC721.mint(signer.address, i + 1);
    }

    // 本次拍卖选择 tokenId = 1
    const tokenId = 1;

    /**
     * 7) 授权：让拍卖合约（代理地址）成为 signer 的 operator
     *    - 为什么需要？
     *      a) 如果 createAuction 或 endAuction 里需要由合约来转移 NFT，
     *         合约必须对该 tokenId 具备操作权限；
     *      b) setApprovalForAll 是“批量授权”，后续可对 signer 名下所有该合约 NFT 操作。
     *    - 注意：如果你的 createAuction 内部会将 NFT 从卖家转入合约托管，
     *            这一步是必须的；否则转移会因权限不足而 revert。
     */
    await testERC721.connect(signer).setApprovalForAll(nftAuctionProxy.address, true);

    /**
     * 8) 创建拍卖
     *    - 参数含义（根据你的 NftAuction 接口）：
     *      duration:            10（秒）
     *      startPrice / minBid: 0.01 ETH
     *      nftContract:         刚部署的 ERC721 地址
     *      tokenId:             1
     */
    await nftAuction.createAuction(
        10,
        ethers.parseEther("0.01"),
        testERC721Address,
        tokenId
    );

    /**
     * 9) 读取刚创建的拍卖，打印观察（可选）
     *    - auctions(0) 说明这可能是第 0 号拍卖
     */
    const auction = await nftAuction.auctions(0);
    console.log("创建拍卖成功：：", auction);

    /**
     * 10) 买家出价
     *     - 通过 payable 的 placeBid 传入 0.01 ETH
     *     - 如果你的合约实现了更高的出价规则（如必须高于当前最高价一定幅度），
     *       需要据此调整测试用的出价值
     */
    await nftAuction.connect(buyer).placeBid(0, { value: ethers.parseEther("0.01") });

    // 等待十秒
    await new Promise((resolve) => setTimeout(resolve, 10 * 1000));

    await nftAuction.connect(signer).endAuction(0);

    /**
     * 13) 断言拍卖结果（读取最新拍卖状态）
     *     - 字段名请与合约结构体保持一致（你的 earlier 代码里用过 maxBidder/maxPrice，
     *       也出现过 highestBidder/highestBid；以当前合约为准）
     */
    const auctionResult = await nftAuction.auctions(0);
    console.log("结束拍卖后读取拍卖成功", auctionResult);
    expect(auctionResult.maxBidder).to.equal(buyer.address);
    expect(auctionResult.maxPrice).to.equal(ethers.parseEther("0.01"));

    /**
     * 14) 验证 NFT 所有权：应已转给买家
     */
    const owner = await testERC721.ownerOf(tokenId);
    console.log("owner::", owner);
    expect(owner).to.equal(buyer.address);
}
