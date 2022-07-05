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
        (Request memory rq, bytes32 rqHash) = makeRequest(1, bytes("Hallo, how are you?"), user, userPrivateKey);
        vm.prank(user);
        inbox.forceResponse(rq);

        // sign response
        bytes memory response = "Very well, thank you.";
        bytes32 responseHash = keccak256(abi.encodePacked(response, rqHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverPrivateKey, responseHash);

        // respond
        inbox.respond(Response(response, rqHash, v, r, s));
    }

    function testPunishLateness() public {
        // forceResponse
        (Request memory rq, bytes32 rqHash) = makeRequest(1, bytes("Hallo, how are you?"), user, userPrivateKey);
        vm.prank(user);
        inbox.forceResponse(rq);

        // make sure immediately finding a late response fails
        vm.expectRevert(stdError.assertionError);
        inbox.punishLateness(rqHash);

        // roll forward without respond and expect success
        vm.roll(100);
        inbox.punishLateness(rqHash);
    }

    function testCannotBeLateForNonexistentRequest() public {
        vm.expectRevert(stdError.assertionError);
        inbox.punishLateness(bytes32("asdf"));

        vm.roll(100);
        vm.expectRevert(stdError.assertionError);
        inbox.punishLateness(bytes32("asdf"));
    }

    function testFastForward() public {}

    function makeRequest(uint256 ticketsUsed, bytes memory body, address publicAddress, uint256 privateKey) public returns (Request memory, bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(ticketsUsed, body, publicAddress));
        (uint8 uv, bytes32 ur, bytes32 us) = vm.sign(privateKey, hash);
        return (Request(ticketsUsed, body, publicAddress, uv, ur, us), hash);
    }
}
