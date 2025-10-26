// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    /*
     * 变量	含义
        msg.sender	调用当前函数的账户地址（或合约地址）
        msg.value	本次调用发送的 ETH 数量（单位：wei）
        msg.data	调用时携带的完整 calldata 数据
        msg.sig	调用函数选择器（前 4 字节）
     */
    constructor(uint256 initialSupply) ERC20("MyToken", "MKT") {
        // sodility的铸币函数
        // 给 msg.sender（部署合约的人）增加 1000 个代币；
        _mint(msg.sender, initialSupply);
    }
}