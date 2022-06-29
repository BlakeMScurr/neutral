// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Neu.sol";
import "../lib/forge-std/src/console.sol";

contract TicketBooth {
    address _server;
    Neu _token;
    uint256 _ticketPrice;

    mapping(address => uint256) totalTickets;
    mapping(address => uint256) usedTickets;

    constructor(address server, Neu token, uint256 ticketPrice) {
        _server = server;
        _token = token;
        _ticketPrice = ticketPrice;
    }

    function buyTickets(address forUser, uint256 amount) public {
        _token.transferFrom(forUser, _server, amount * _ticketPrice);
        totalTickets[forUser] = totalTickets[forUser] + amount;
    }

    function useTickets(uint256 amount) public {
        assert(usedTickets[msg.sender] + amount <= totalTickets[msg.sender]);
        usedTickets[msg.sender] = usedTickets[msg.sender] + amount;
    }

    function redeemVoucher(address forUser, uint256 tickets, uint8 v, bytes32 r, bytes32 s) public {
        assert(ecrecover(keccak256(abi.encodePacked(tickets, forUser)), v, r, s) == _server); // Check that the server has signed a message giving the user some tickets
        assert(tickets > totalTickets[forUser]);
        totalTickets[forUser] = tickets;
    }

    // View functions
    function getTotalTickets(address user) public view returns (uint256) {
        return totalTickets[user];
    }

    function getUsedTickets(address user) public view returns (uint256) {
        return usedTickets[user];
    }
}
