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