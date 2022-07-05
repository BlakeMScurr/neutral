// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Inbox.sol";
import "../src/Neu.sol";

contract ContractTest is Test {
    Inbox inbox;
    Neu token;
    address server;
    uint256 serverPrivateKey;

    address user;
    uint256 userPrivateKey;

    function setUp() public {
        // Create contracts
        token = new Neu();
        serverPrivateKey = 1;
        server = vm.addr(serverPrivateKey);
        userPrivateKey = 2;
        user = vm.addr(userPrivateKey);
        inbox = new Inbox(server, token, 2, 1, 10);

        // Get Neu
        assertEq(inbox.getTotalTickets(user), 0);
        token.transfer(user, 100);

        // Buy Tickets
        vm.prank(user);
        token.approve(address(inbox), 100);
        inbox.buyTickets(user, 1);
        assertEq(inbox.getTotalTickets(user), 1);

    }

    function testForce() public {
        // forceResponse
        bytes memory request = "Hallo, how are you?";
        uint256 ticketsUsed = 1;
        bytes32 hash = keccak256(abi.encodePacked(ticketsUsed, request));
        (uint8 uv, bytes32 ur, bytes32 us) = vm.sign(userPrivateKey, hash);
        vm.prank(user);
        inbox.forceResponse(ticketsUsed, request, uv, ur, us);

        // sign response
        bytes memory response = "Very well, thank you.";
        bytes32 requestHash = keccak256(request);
        bytes32 responseHash = keccak256(abi.encodePacked(response, requestHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverPrivateKey, responseHash);
        
        // respond
        inbox.respond(response, requestHash, v, r, s);
    }

    function testLateResponse() public {
        // forceResponse
        bytes memory request = "Hallo, how are you?";
        uint256 ticketsUsed = 1;
        bytes32 hash = keccak256(abi.encodePacked(ticketsUsed, request));
        (uint8 uv, bytes32 ur, bytes32 us) = vm.sign(userPrivateKey, hash);
        vm.prank(user);
        inbox.forceResponse(ticketsUsed, request, uv, ur, us);

        // make sure immediately finding a late response fails
        vm.expectRevert(stdError.assertionError);
        bytes32 requestHash = keccak256(request);
        inbox.lateResponse(requestHash);

        // roll forward without respond and expect success
        vm.roll(100);
        inbox.lateResponse(requestHash);
    }

    function testCannotBeLateForNonexistentRequest() public {
        vm.expectRevert(stdError.assertionError);
        inbox.lateResponse(bytes32("asdf"));

        vm.roll(100);
        vm.expectRevert(stdError.assertionError);
        inbox.lateResponse(bytes32("asdf"));
    }
}
