// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PoolToken.sol";
import "./Timelock.sol";
import "./Governor.sol";

interface IPrivateAirdrop {
    function communityAdmin(uint id) external view returns(address);
}

contract PoolManager {

    struct PoolInfo {
        PoolToken poolToken;
        Timelock timelock;
        Governor governor;
        uint poolRatio;
        address fundingToken;
    }

    ICommunityToken public communityToken;

    IPrivateAirdrop public privateAirdrop;

    mapping(uint => PoolInfo) public poolInfos;


    constructor(address _privateAirdrop,address _communityToken){
        privateAirdrop = IPrivateAirdrop(_privateAirdrop);
        communityToken = ICommunityToken(_communityToken);
    } 

    function createPool(uint id, string memory name, string memory symbol, uint poolRatio, address fundingToken) external {
        require(communityToken.balanceOf(msg.sender, id) > 0 && privateAirdrop.communityAdmin(id) == msg.sender, "Not Authorised");
        require(poolInfos[id].fundingToken == address(0), "Already created pool");

        require(poolRatio != 0, "Can not be zero");

        require(fundingToken != address(0), "Funding Token address can not be zero");

        PoolInfo memory poolInfo = PoolInfo({
            poolToken : new PoolToken(name, symbol),
            poolRatio : poolRatio,
            fundingToken : fundingToken,
            timelock: new Timelock(address(this), 2 days, 1 days),
            governor: new Governor()
        });

        poolInfo.timelock.setPendingAdmin(address(poolInfo.governor));

        poolInfo.governor.initialize(address(communityToken),id,address(poolInfo.timelock), address(poolInfo.poolToken), 5 days, 3600, 1000e18);

        poolInfos[id] = poolInfo;
    }


    function investInPool(uint id, uint fundingAmount) external {
        require(communityToken.balanceOf(msg.sender, id) > 0, "Not Authorised");
        require(poolInfos[id].fundingToken != address(0), "Already created pool");

        PoolInfo memory poolInfo = poolInfos[id];

        uint tokenToBeTransferred = poolInfo.poolRatio * fundingAmount / 1e18;

        PoolToken poolToken = poolInfo.poolToken;

        require(poolToken.balanceOf(address(this)) >=  tokenToBeTransferred, "Invalid Amount");

        require(IERC20(poolInfo.fundingToken).transferFrom(msg.sender, address(this), fundingAmount), "Funding Token transfer failed");

        poolToken.transfer(msg.sender, tokenToBeTransferred);

    }


}