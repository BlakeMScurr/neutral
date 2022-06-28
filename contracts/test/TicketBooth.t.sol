// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/TicketBooth.sol";
import "../src/Neu.sol";

contract ContractTest is Test {
    TicketBooth booth;
    Neu token;
    function setUp() public {
        token = new Neu();
        booth = new TicketBooth(msg.sender, token, 2);
    }

    function testBuyTickets() public {
        assertEq(booth.getTotalTickets(address(1)), 0);
        token.transfer(address(1), 100);
        vm.prank(address(1));
        emit log_uint(123);
        console.log("asdfasdf");
        booth.buyTickets(1);
        // assertEq(booth.getTotalTickets(address(1)), 5);
    }
}
