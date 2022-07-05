// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Neu.sol";
import "./TicketBooth.sol";
import "../lib/forge-std/src/console.sol";

contract Inbox is TicketBooth {
    uint256 _forceResponseCost;
    uint256 _leeway;
    mapping(bytes32 => uint256) public requests;

    event ForceResponse(address indexed _from, bytes request);
    event Respond(bytes32 indexed requestHash);

    constructor(
        address server,
        Neu token,
        uint256 ticketPrice,
        uint256 forceResponseCost,
        uint256 leeway
    ) TicketBooth(server, token, ticketPrice) {
        _forceResponseCost = forceResponseCost;
        _leeway = leeway;
    }

    // Forces the server to respond to the user's request
    function forceResponse(uint256 ticketsUsed, bytes calldata request, uint8 v, bytes32 r, bytes32 s) public {
        assert(ecrecover(keccak256(abi.encodePacked(ticketsUsed, request)), v, r, s) == msg.sender); // Make sure the message sender signed the request
        assert(_forceResponseCost + getUsedTickets(msg.sender) <= ticketsUsed); // Make sure they have spent enough tickets to send this request

        useTickets(ticketsUsed);
        requests[keccak256(request)] = block.number;
        emit ForceResponse(msg.sender, request);
    }

    // Addresses the user's request with the server's response
    function respond(bytes calldata response, bytes32 requestHash, uint8 v, bytes32 r, bytes32 s) public {
        assert(ecrecover(keccak256(abi.encodePacked(response, requestHash)), v, r, s) == _server);
        delete requests[requestHash];
        emit Respond(requestHash);
    }

    // Slashes the server's bond if it's late to respond to a user's request
    function lateResponse(bytes32 requestHash) public {
        assert(requests[requestHash] != 0); // Unset requestHashes can't have late response
        assert(requests[requestHash] + _leeway < block.number);
        // TODO: slash bond
    }

    // fastForward lets the server resolve offchain requests by responding to the latest one and making
    // it impossible for the user to force it to respond to earlier ones.
    function fastForward() public {}
}