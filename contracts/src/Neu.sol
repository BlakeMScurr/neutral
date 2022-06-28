// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract Neu is ERC20PresetFixedSupply {
    constructor() ERC20PresetFixedSupply("Neu", "Neu", 1000000000000, msg.sender) {}
}
