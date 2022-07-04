// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Neu.sol";
import "./TicketBooth.sol";
import "../lib/forge-std/src/console.sol";

contract Queue is TicketBooth {
    uint256 _enqueueCost;
    uint256 _leeway;
    mapping(bytes32 => uint256) public requests;

    event Enqueue(address indexed _from, bytes request);
    event Dequeue(bytes32 indexed requestHash);

    constructor(
        address server,
        Neu token,
        uint256 ticketPrice,
        uint256 enqueueCost,
        uint256 leeway
    ) TicketBooth(server, token, ticketPrice) {
        _enqueueCost = enqueueCost;
        _leeway = leeway;
    }

    function enqueue(uint256 ticketsUsed, bytes calldata request, uint8 v, bytes32 r, bytes32 s) public {
        assert(ecrecover(keccak256(abi.encodePacked(ticketsUsed, request)), v, r, s) == msg.sender); // Make sure the message sender signed the request
        assert(_enqueueCost + getUsedTickets(msg.sender) <= ticketsUsed); // Make sure they have spent enough tickets to send this request

        useTickets(ticketsUsed);
        requests[keccak256(request)] = block.number;
        emit Enqueue(msg.sender, request);
    }

    function dequeue(bytes calldata response, bytes32 requestHash, uint8 v, bytes32 r, bytes32 s) public {
        assert(ecrecover(keccak256(abi.encodePacked(response, requestHash)), v, r, s) == _server);
        delete requests[requestHash];
        emit Dequeue(requestHash);
    }

    function lateResponse(bytes32 requestHash) public {
        assert(requests[requestHash] != 0); // Unset requestHashes can't have late response
        assert(requests[requestHash] + _leeway < block.number);
        // TODO: slash bond
    }
}