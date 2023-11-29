// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockFailedTransfer is ERC20 {
    constructor() ERC20("FailedTransfer", "FT") {}

    function transfer(address, /*recipient*/ uint256 /*amount*/ ) public pure override returns (bool) {
        return false;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
