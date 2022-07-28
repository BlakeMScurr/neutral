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

    uint256 requestWindow = 5;

    function setUp() public {
        // Create contracts
        token = new Neu();
        serverPrivateKey = 1;
        server = vm.addr(serverPrivateKey);
        userPrivateKey = 2;
        user = vm.addr(userPrivateKey);
        inbox = new Inbox(server, token, 2, 1, 10, requestWindow);

        // Get Neu
        assertEq(inbox.getTotalTickets(user), 0);
        token.transfer(user, 100);

        // Buy Tickets
        vm.prank(user);
        token.approve(address(inbox), 100);
        inbox.buyTickets(user, 50);
        assertEq(inbox.getTotalTickets(user), 50);
    }

    function testForce() public {
        (Request memory rq, bytes32 rqHash) = makeRequest(1, bytes("Hallo, how are you?"), user, userPrivateKey, block.number);
        inbox.forceResponse(rq);
        inbox.respond(makeResponse("Very well, thank you.", rqHash, serverPrivateKey));
    }

    function testPunishLateness() public {
        // forceResponse
        (Request memory rq, bytes32 rqHash) = makeRequest(1, bytes("Hallo, how are you?"), user, userPrivateKey, block.number);
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

    function testFastForward() public {
        // should be able to use a signed request to use many tickets
        assertEq(inbox.getUsedTickets(user), 0);
        (Request memory rq, bytes32 rqHash) = makeRequest(50, bytes("later request"), user, userPrivateKey, block.number);
        inbox.fastForward(rq, makeResponse("later response.", rqHash, serverPrivateKey));
        assertEq(inbox.getUsedTickets(user), 50);

        // should not be able to roll those tickets back using an earlier signed response
        (rq, rqHash) = makeRequest(10, bytes("earlier request"), user, userPrivateKey, block.number);
        inbox.fastForward(rq, makeResponse("earlier response.", rqHash, serverPrivateKey));
        assertEq(inbox.getUsedTickets(user), 50);
    }

    function makeResponse(bytes memory body, bytes32 rqHash, uint256 serverPK) public returns (Response memory) {
        bytes32 responseHash = keccak256(abi.encodePacked(body, rqHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverPK, responseHash);
        return Response(body, rqHash, v, r, s);
    }

    function makeRequest(uint256 ticketsUsed, bytes memory body, address publicAddress, uint256 privateKey, uint256 blockNumber) public returns (Request memory, bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(ticketsUsed, body, publicAddress));
        (uint8 uv, bytes32 ur, bytes32 us) = vm.sign(privateKey, hash);
        return (Request(body, publicAddress, blockNumber, ticketsUsed, uv, ur, us), hash);
    }
}
