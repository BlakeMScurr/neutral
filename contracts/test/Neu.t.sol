// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Neu.sol";

contract ContractTest is Test {
    Neu token;
    function setUp() public {
        token = new Neu();
    }

    function testSupply() public {
        assertEq(token.totalSupply(), 1000000000000);
    }
}
