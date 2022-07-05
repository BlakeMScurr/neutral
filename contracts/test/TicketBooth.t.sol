// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/TicketBooth.sol";
import "../src/Neu.sol";

contract ContractTest is Test {
    PassThrough booth;
    Neu token;
    address server;
    uint256 serverPrivateKey;
    function setUp() public {
        token = new Neu();
        server = vm.addr(1);
        serverPrivateKey = 1;
        booth = new PassThrough(server, token, 2);
    }

    function testBuyUse() public {
        assertEq(booth.getTotalTickets(address(1)), 0);
        token.transfer(address(1), 100);

        // Buy Tickets
        vm.prank(address(1));
        token.approve(address(booth), 100);
        booth.buyTickets(address(1), 1);
        assertEq(booth.getTotalTickets(address(1)), 1);

        // Use Tickets
        assertEq(booth.getUsedTickets(address(1)), 0);
        assertEq(booth._useTicketsUpTo(1, address(1)), 1);
        assertEq(booth.getTotalTickets(address(1)), 1);
        assertEq(booth.getUsedTickets(address(1)), 1);

        // Can't use more tickets than we have
        assertEq(booth._useTicketsUpTo(2, address(1)), 0);
    }

    function testVoucher() public {
        assertEq(booth.getTotalTickets(address(1)), 0);

        uint256 tickets = 1000;
        bytes32 hash = keccak256(abi.encodePacked(tickets, address(1)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverPrivateKey, hash);
        booth.redeemVoucher(address(1), tickets, v, r, s);
        assertEq(booth.getTotalTickets(address(1)), 1000);
    }
}

contract PassThrough is TicketBooth {
    constructor(address server, Neu token, uint256 ticketPrice) TicketBooth(server, token, ticketPrice) {}

    function _useTicketsUpTo(uint256 ticketNumber, address user) public returns (uint256) {
        return useTicketsUpTo(ticketNumber, user);
    }
}