# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node # 初始化本地节点，生成20个钱包
npx hardhat ignition deploy ./ignition/modules/Lock.js --network localhost
```
# hardhat 初始化过程
    1、npx hardhat --init
    2、选择2版本的
    3、先本地起20个钱包的本地节点
    4、在本地部署hardhat
## 部署到测试网sepolia
    1、npx hardhat ignition deploy ./ignition/modules/Lock.js --network sepolia
    2、打开sepolia.etherscan.io 查看部署的合约

## 环境变量的使用
    1、npm install dotenv
    2、npx hardhat ignition deploy ./ignition/modules/Lock.js --network sepolia
重新部署是同一个合约地址，这是因为没有重新部署，iginiton检测到合约modules没有变就复用之前部署的地址

那么如何部署一个新的合约呢？

    Hardhat Ignition 检测到你的合约逻辑变了（bytecode 改了），
    但因为它默认不允许直接覆盖旧部署，所以报了 “reconciliation failed”。
    解决方法：要么删除旧状态重新部署，要么新建一个模块或部署版本。

所以在开发阶段（需要反复部署合约）
    
    rm -rf ignition/deployments/sepolia && npx hardhat ignition deploy ./ignition/modules/LockModule.js --network sepolia

    ignition部署时，不会verify代码，所以ether上看到的只是字节码
    ignition自动verify的条件：
| 条件                                              | 说明                                |
| ----------------------------------------------- | --------------------------------- |
| ✅ 网络是公共链（如 sepolia、mainnet、holesky 等）           | 本地链或 hardhat 网络不会验证               |
| ✅ `etherscan.apiKey` 已在 `hardhat.config.js` 中配置 | Ignition 自动使用该 API key 调用验证接口     |
| ✅ Etherscan 支持当前链                               | 比如 sepolia、goerli 都支持             |
| ✅ 模块中合约部署成功且是“独立部署”（非代理）                        | 对于 proxy 或 UUPS 模式不会自动验证          |
| ✅ 合约的 artifact、构造参数、编译设置未变化                     | 若二次部署逻辑不同（或字节码不同），Ignition 不会重复验证 |

## task
hardhat本身就是一个任务执行系统，那怎么定义任务呢？如何执行任务呢？ -- task
```js
// tasks/accounts.js
const { task } = require("hardhat/config");

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});
```
运行：
npx hardhat accounts
