// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Neu.sol";
import "./TicketBooth.sol";
import "../lib/forge-std/src/console.sol";

contract Inbox is TicketBooth {
    uint256 _forceResponseCost;
    uint256 _leeway;
    mapping(bytes32 => uint256) public requests;

    event ForceResponse(address indexed _from, bytes32 indexed hash, bytes request);
    event Respond(bytes32 indexed requestHash, bytes response);

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
    function forceResponse(Request calldata rq) public {
        (bytes32 hash, address user) = hashAndSigner(rq);
        assert(useTicketsUpTo(rq.ticketsUsed, user) >= _forceResponseCost);
        requests[hash] = block.number;
        emit ForceResponse(user, hash, rq.body);
    }

    // Addresses the user's request with the server's response
    function respond(Response calldata resp) public {
        assert(signer(resp) == _server);
        delete requests[resp.requestHash];
        emit Respond(resp.requestHash, resp.body);
    }

    // Slashes the server's bond if it's late to respond to a user's request
    function punishLateness(bytes32 requestHash) public view {
        assert(requests[requestHash] != 0); // Unset requestHashes can't have late response
        assert(requests[requestHash] + _leeway < block.number);
        // TODO: slash bond
    }

    // Lets the server resolve offchain requests by responding to the latest one, making
    // it impossible for the user to force it to respond to earlier ones.
    function fastForward(Request calldata rq, Response calldata resp) public {
        (bytes32 rqHash, address user) = hashAndSigner(rq);
        assert(signer(resp) == _server);
        assert(rqHash == resp.requestHash);
        useTicketsUpTo(rq.ticketsUsed, user);
    }

    // Utilities
    function signer(Response calldata resp) public pure returns(address) {
        bytes32 hash = keccak256(abi.encodePacked(resp.body, resp.requestHash));
        return ecrecover(hash, resp.v, resp.r, resp.s);
    }

    function hashAndSigner(Request calldata rq) public pure returns(bytes32, address) {
        bytes32 hash = keccak256(abi.encodePacked(rq.ticketsUsed, rq.body, rq.signer));
        return (hash, ecrecover(hash, rq.v, rq.r, rq.s));
    }
}

struct Request {
    // Content
    uint256 ticketsUsed;
    bytes body;
    address signer;

    // Signature
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct Response {
    // content
    bytes body;
    bytes32 requestHash;

    // signature
    uint8 v;
    bytes32 r;
    bytes32 s;
}