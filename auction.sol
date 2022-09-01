// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/access/AccessControlEnumerable.sol";

contract EnglishAuction is AccessControlEnumerable {

    modifier isAdmin(){
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role");
        _;
    }

    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);


    IERC721 public nft;
    uint public nftId;

    address payable public seller;
    uint public endAt;
    bool public started;

    address public highestBidder;
    uint public highestBid;
    uint public durationInDays;
    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid,
        uint  _durationInDays
    ) {
        require(_nft!=address(0), "Nft address cannot be null.");
        nft = IERC721(_nft);
        nftId = _nftId;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        seller = payable(_msgSender());
        highestBid = _startingBid;
        durationInDays = _durationInDays;
    }

    function start() external isAdmin {
        require(!started, "Auction already started.");

        nft.transferFrom(_msgSender(), address(this), nftId);
        started = true;
        endAt = block.timestamp + (durationInDays * 1 days);

        emit Start();
    }

    function bid() external payable {
        require(started, "Auction not started.");
        require(block.timestamp < endAt, "Auction has ended.");
        require(highestBidder != _msgSender(), "You have the higest bid.");

        uint currentBid = bids[_msgSender()] + msg.value;
        require(currentBid > highestBid, "You hava to provide highest bid than current price.");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = _msgSender();
        highestBid = currentBid;
        bids[_msgSender()] = 0;
        emit Bid(highestBidder, highestBid);
    }

    function withdraw() external {
        uint bal = bids[_msgSender()];
        require(bal > 0, "You have no bids to withdraw");
        bids[_msgSender()] = 0;
        payable(_msgSender()).transfer(bal);
        emit Withdraw(_msgSender(), bal);
    }

    function end() external {
        require(started, "Auction not started.");
        require(block.timestamp >= endAt, "Auction has ended.");
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
