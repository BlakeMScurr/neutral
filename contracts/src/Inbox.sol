// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Neu.sol";
import "./TicketBooth.sol";
import "../lib/forge-std/src/console.sol";

contract Inbox is TicketBooth {
    uint256 _forceResponseCost;
    uint256 _responseWindow;
    uint256 _requestWindow;
    mapping(bytes32 => uint256) public requests;

    event ForceResponse(address indexed _from, bytes32 indexed hash, bytes request);
    event Respond(bytes32 indexed requestHash, bytes response);

    constructor(
        address server,
        Neu token,
        uint256 ticketPrice,
        uint256 forceResponseCost,
        uint256 responseWindow,
        uint256 requestWindow
    ) TicketBooth(server, token, ticketPrice) {
        _forceResponseCost = forceResponseCost;
        _responseWindow = responseWindow;
        _requestWindow = requestWindow;
    }

    // Forces the server to respond to the user's request
    function forceResponse(Request calldata rq) public {
        // Only requests from a given window after the current block are acceptable.
        // The server can't respond to a search request dated in the future, since it doesn't know the state
        // of the store at that time. It can't respond to a store request from the past since the state is
        // already set at that point.
        // To allow the requests to work offchain, the blockNumber must be a signed part of the request, but a
        // client can't be certain that their forceRequest transaction will be accepted at the exact block specified
        // in the request, so we give them some leeway, namely _requestWindow blocks, in which their transaction is acceptable.
        assert(block.number <= rq.blockNumber && rq.blockNumber <= block.number + _requestWindow);

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
        assert(requests[requestHash] + _responseWindow < block.number);
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
    bytes body;
    address signer;
    uint256 blockNumber; 
    uint256 ticketsUsed;

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