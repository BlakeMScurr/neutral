// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Queue.sol";
import "../src/Neu.sol";

contract ContractTest is Test {
    Queue queue;
    Neu token;
    address server;
    uint256 serverPrivateKey;

    function setUp() public {
        // Create contracts
        token = new Neu();
        server = vm.addr(1);
        serverPrivateKey = 1;
        queue = new Queue(server, token, 2, 1, 10);

        // Get Neu
        assertEq(queue.getTotalTickets(address(1)), 0);
        token.transfer(address(1), 100);

        // Buy Tickets
        vm.prank(address(1));
        token.approve(address(queue), 100);
        queue.buyTickets(address(1), 1);
        assertEq(queue.getTotalTickets(address(1)), 1);

    }

    function testEnqueueDeque() public {
        // enqueue
        vm.prank(address(1));
        bytes memory request = "Hallo, how are you?";
        bytes32 requestHash = keccak256(request);
        queue.enqueue(request);

        // sign dequeue response
        bytes memory response = "Very well, thank you.";
        bytes32 responseHash = keccak256(abi.encodePacked(response, requestHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(serverPrivateKey, responseHash);
        
        // dequeue
        queue.dequeue(response, requestHash, v, r, s);
    }

    function testLateResponse() public {
        // enqueue
        vm.prank(address(1));
        bytes memory request = "Hallo, how are you?";
        bytes32 requestHash = keccak256(request);
        queue.enqueue(request);

        // make sure immediately finding a late response fails fails
        vm.expectRevert(stdError.assertionError);
        queue.lateResponse(requestHash);

        // roll forward without dequeue and expect success
        vm.roll(100);
        queue.lateResponse(requestHash);
    }

    function testCannotBeLateForNonexistentRequest() public {
        vm.expectRevert(stdError.assertionError);
        queue.lateResponse(bytes32("asdf"));

        vm.roll(100);
        vm.expectRevert(stdError.assertionError);
        queue.lateResponse(bytes32("asdf"));
    }
}
