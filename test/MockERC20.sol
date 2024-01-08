// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("ERC20Mock", "M20") {
        this;
    }

    // mint function mints tokens to the specified address
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
