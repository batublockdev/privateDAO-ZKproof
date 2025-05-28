// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract MyToken is ERC20, ERC20Permit, ERC20Votes {
    error MyToken__AlreadyHolder(address holder);
    error MyToken__TransferNotAllowed();

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function mint(address to) public {
        if (_isHolder[to]) {
            revert MyToken__AlreadyHolder(to);
        }
        _mint(to, 1e18);
        _updateHolder(to, to);
    }

    function burn(address from) public {
        _burn(from, 1e18); // Burn 1 token for simplicity
        _updateHolder(from, address(0));
    }

    function transfer(
        address to,
        uint256 amount
    ) public override(ERC20) returns (bool) {
        revert MyToken__TransferNotAllowed();
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(ERC20) returns (bool) {
        revert MyToken__TransferNotAllowed();
    }

    function totalHolderCount() public view returns (uint256) {
        return holderCount;
    }
}
