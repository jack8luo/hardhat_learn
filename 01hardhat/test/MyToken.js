const hre = require("hardhat")
const {expect} = require("chai")

describe("MyToken Test", async() =>{
    // 部署合约
    const {ethers} = hre;

    const initialSupply = 1000;

    let MyTokenContract;

    // 两个账号
    let account1, account2;

    beforeEach(async () => {

        [account1, account2] = await ethers.getSigners();

        const MyToken = await ethers.getContractFactory("MyToken")

        // 默认account1部署合约
        MyTokenContract = await MyToken.connect(account2).deploy(initialSupply)

        await MyTokenContract.waitForDeployment()

        const newVar = await MyTokenContract.getAddress();

        expect(newVar).to.length.greaterThan(0)

        console.log("合约地址：", newVar)
    });


    it('验证合约的参数 name， symbol，decimals', async () => {
        const name = await MyTokenContract.name();
        const symbol = await MyTokenContract.symbol();
        const decimals = await MyTokenContract.decimals();

        expect(name).to.equal("MyToken")
        expect(symbol).to.equal("MTK")
        expect(decimals).to.equal(18)
    });

    it('测试转账', async () => {

        const resp = await MyTokenContract.transfer(account1, initialSupply /2);

        console.log("resp:", resp)

        const bigint = await MyTokenContract.balanceOf(account2);

        expect(bigint).to.equal(initialSupply/2)

    });
})