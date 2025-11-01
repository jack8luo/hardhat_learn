// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftAuction is Initializable, UUPSUpgradeable{

    // 结构体
    struct Auction {
        address seller;      // 卖家地址
        uint256 startTime;  //开始时间
        uint256 duration;   //  持续时间
        uint256 minPrice;    // 最低价格
        uint256 maxPrice;    // 最高价格
        address maxBidder;   // 最高出价人
        bool ended;          // 拍卖是否结束
        address nftContract; //合约地址
        uint256 tokenId; //NFTID
    }

    //状态变量
    mapping(uint256 => Auction) public auctions;    // tokenId => Auction 拍卖信息
    // 下一个拍卖id
    uint256 public nextAuctionId;
    // 管理员地址
    address public admin;

    function initialize() initializer public {
        admin = msg.sender;
    }
    
    // 创建拍卖
    function createAuction(uint256 _duration, uint256 _minPrice, address _nftAddress, uint256 _tokenId) public {
        // 只有管理员可以创建拍卖
        require(msg.sender == admin, unicode"只有管理员可以创建拍卖");
        require(_duration > 0, unicode"持续时间必须大于0");
        require(_minPrice > 0, unicode"最小金额必须大于0");

        // 转移NFT到合约
        IERC721(_nftAddress).approve(address(this), _tokenId);

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: _duration,
            minPrice: _minPrice,
            ended: false,
            maxPrice: 0,
            maxBidder: address(0),
            startTime: block.timestamp,
            nftContract: _nftAddress,
            tokenId: _tokenId
        });
        nextAuctionId++;
    }

    // 买家参与买单
    function placeBid(uint256 _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];
        // 判断拍卖是否结束
        require(!auction.ended && auction.duration + auction.startTime > block.timestamp, unicode"拍卖已结束");
        // 判断价格是否大于当前价格
        require(msg.value > auction.maxPrice && msg.value >= auction.minPrice, unicode"拍卖价格必须大于最近价格");
        // 退款
        if(auction.maxBidder != address(0)){
            payable(auction.maxBidder).transfer(auction.maxPrice);
        }
        auction.maxPrice= msg.value;
        auction.maxBidder= msg.sender;
    }

// 结束拍卖
    function endAuction(uint256 _auctionID) external {
        // storage 链上数据修改
        Auction storage auction = auctions[_auctionID];
        // 判断当前拍卖是否结束
        require(!auction.ended && (auction.startTime + auction.duration) <= block.timestamp, "Auction has not ended");
        // 转移NFT到最高出价者
        IERC721(auction.nftContract).safeTransferFrom(admin, auction.maxBidder, auction.tokenId);
        // 转移剩余的资金到卖家
        // payable(address(this)).transfer(address(this).balance);
        auction.ended = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override view {
        // 只有管理员可以升级合约
        require(msg.sender == admin, unicode"只有管理员可以升级合约");
    }
}