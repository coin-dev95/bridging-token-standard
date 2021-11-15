// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @dev Context variant with ERC2771 support. Closely based off of
 *      openzeppelin/contracts/metatx/ERC2771Context.sol
 *      but modified to add setTrustedForwarder function
 *      and removed constructor.
 */
abstract contract ERC2771ContextUpdateable is AccessControlEnumerable {
    address public _trustedForwarder;

    event TrustedForwarderChanged(address indexed trustedForwarder, address indexed actor);

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function setTrustedForwarder(address trustedForwarder) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role");

        _trustedForwarder = trustedForwarder;
        emit TrustedForwarderChanged(trustedForwarder, msg.sender);
    }
}
