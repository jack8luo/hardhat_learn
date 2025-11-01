// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

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
        address tokenAddress; // 参与竞价的资产类型 0x代表eth ，其他表示erc20
    }

    //状态变量
    mapping(uint256 => Auction) public auctions;    // tokenId => Auction 拍卖信息
    // 下一个拍卖id
    uint256 public nextAuctionId;
    // 管理员地址
    address public admin;

//    AggregatorV3Interface internal dataFeed;
    mapping(address  => AggregatorV3Interface) public priceFeeds;

    function setPriceETHFeed(address _priceETHFeed) public  {
        dataFeed = AggregatorV3Interface(_priceETHFeed);
    }

    /**
    * Returns the latest answer.
    * eth->usd 385521271400
    * usdc->usd 99984833
    */
    function getChainlinkDataFeedLatestAnswer(address tokenAddress) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        // prettier-ignore
        (
        /* uint80 roundId */
        ,
        int256 answer,
        /*uint256 startedAt*/
        ,
        /*uint256 updatedAt*/
        ,
        /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    // q：为什么部署合约要先iniitialize
    // 因为这是可升级（UUPS）合约。代理模式下构造函数不会执行，所以需要用 initialize() 在代理合约的存储里完成一次性的初始化（设置 admin、调用父类初始化等）。无论主网还是测试网，原理一样。
    function initialize() initializer public {
        admin = msg.sender;
    }
    /**
     * 结论：现在这个合约只用链上原生币付款出价——也就是 msg.value 里的那种币。
    部署在以太坊主网/测试网 → 用 ETH（wei 计价）。
    部署在 BSC → 用 BNB。
    （总之就是该链的原生币
     */
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
            tokenId: _tokenId,
            tokenAddress: address(0)
        });
        nextAuctionId++;
    }

    // 买家参与买单
    // 参数： NFT 、 开始价格 、
    function placeBid(uint256 _auctionId, uint256 amount, address _tokenAddress) external payable {
        //  统一的价值尺度

        Auction storage auction = auctions[_auctionId];
        // 判断拍卖是否结束
        require(!auction.ended && auction.duration + auction.startTime > block.timestamp, unicode"拍卖已结束");

        uint payValue;
        if (_tokenAddress != address(0)) {
            // 处理 ERC20
            // 检查是否是 ERC20 资产
            payValue = amount * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        } else {
            // 处理 ETH
            amount = msg.value;

            payValue = amount * uint(getChainlinkDataFeedLatestAnswer(address(0)));
        }

        uint startPriceValue = auction.startPrice *
                            uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));

        uint highestBidValue = auction.highestBid *
                            uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));

        require(
            payValue >= startPriceValue && payValue > highestBidValue,
            "Bid must be higher than the current highest bid"
        );

        // 转移 ERC20 到合约
        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        }

        // 退还前最高价
        if (auction.maxPrice > 0) {
            if (auction.tokenAddress == address(0)) {
                // auction.tokenAddress = _tokenAddress;
                payable(auction.maxBidder).transfer(auction.maxPrice);
            } else {
                // 退回之前的ERC20
                IERC20(auction.tokenAddress).transfer(
                    auction.maxBidder,
                    auction.maxPrice
                );
            }
        }

        auction.tokenAddress = _tokenAddress;
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