// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./PoolToken.sol";

interface ITimelock {
    function initialize(address admin_, uint delay_, uint minDelay_) external;
    function setPendingAdmin(address pendingAdmin_) external;
}

interface IGovernor {
    function initialize(address communityToken_, uint id,address timelock_, address comp_, uint votingPeriod_, uint votingDelay_, uint proposalThreshold_) external;
}

interface ICommunityToken {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function exists(uint id) external view returns (bool);
}
interface IPrivateAirdrop {
    function communityAdmin(uint id) external view returns(address);
    function communityToken() external view returns(ICommunityToken);
}

contract PoolManager {

    struct PoolInfo {
        PoolToken poolToken;
        ITimelock timelock;
        IGovernor governor;
        uint poolRatio;
        address fundingToken;
    }

    ICommunityToken public communityToken;

    IPrivateAirdrop public privateAirdrop;

    mapping(uint => PoolInfo) public poolInfos;

    address governorImplementation;
    address timelockImplementation;

    constructor(address _privateAirdrop, address _governorImpl, address _timelockImpl){
        privateAirdrop = IPrivateAirdrop(_privateAirdrop);
        communityToken = privateAirdrop.communityToken();
        governorImplementation = _governorImpl;
        timelockImplementation = _timelockImpl;
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
            timelock: ITimelock(Clones.clone(timelockImplementation)),
            governor: IGovernor(Clones.clone(governorImplementation))
        });
        poolInfo.timelock.initialize(address(poolInfo.governor), 2 days, 1 days);

        poolInfo.governor.initialize(address(communityToken),id,address(poolInfo.timelock), address(poolInfo.poolToken), 11520, 3600, 1000e18);

        poolInfos[id] = poolInfo;
    }


    function investInPool(uint id, uint fundingAmount) external {
        require(communityToken.balanceOf(msg.sender, id) > 0, "Not Authorised");
        require(poolInfos[id].fundingToken != address(0), "Already created pool");

        PoolInfo memory poolInfo = poolInfos[id];

        uint tokenToBeTransferred = poolInfo.poolRatio * fundingAmount / 1e18;

        PoolToken poolToken = poolInfo.poolToken;

        require(poolToken.balanceOf(address(this)) >=  tokenToBeTransferred, "Invalid Amount");

        require(IERC20(poolInfo.fundingToken).transferFrom(msg.sender, address(poolInfo.timelock), fundingAmount), "Funding Token transfer failed");

        poolToken.transfer(msg.sender, tokenToBeTransferred);

    }


}