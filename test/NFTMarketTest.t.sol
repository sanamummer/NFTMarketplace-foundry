// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/Marketplace.sol"; // Adjust the path to your NFTMarket contract
import "../src/ERC721.sol"; // Adjust the path to your MyNFT contract
import "../src/ERC20.sol"; // Adjust the path to your MoonToken contract
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTMarketTest is Test, IERC721Receiver {
    NFTMarket market;
    MyNFT myNFT;
    MoonToken moonToken;
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        moonToken = new MoonToken();
        market = new NFTMarket(address(moonToken));
        myNFT = new MyNFT(address(market)); // Now market has a valid address
        moonToken.transfer(user1, 1000 * 10 ** 18); // Provide user1 some tokens for testing
    }

    function testListAndBuyNFT() public {
        // Mint an NFT to list
        string memory tokenURI = "https://example.com/nft";
        uint256 newItemId = myNFT.mintNFT(tokenURI, 5);
        myNFT.approve(address(market), newItemId);

        // List the NFT on the market
        uint256 price = 100 * 10 ** 18;
        uint256 royaltyAmount = (price * 5) / 100;
        uint256 marketPlaceFee = (price * 25) / 1000;
        market.listNFTs(address(myNFT), newItemId, price);

        // Simulate user1 buying the NFT
        vm.startPrank(user1);
        uint256 totalAmount = price + royaltyAmount + marketPlaceFee;
        moonToken.approve(address(market), totalAmount);
        market.buyNFT(newItemId);
        vm.stopPrank();
        
        // Calculate expected balances
        uint256 intialBalance = 1000 * 10 ** 18;
        uint256 expectedBalanceAfterPurchase = intialBalance - totalAmount;

        // Assertions
        assertEq(myNFT.ownerOf(newItemId), user1, "User1 should own the NFT after purchase");
        assertEq(moonToken.balanceOf(user1), expectedBalanceAfterPurchase, "Incorrect balance after purchase");
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
