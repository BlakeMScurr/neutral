// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Neu.sol";
import "../lib/forge-std/src/console.sol";

contract TicketBooth {
    address _server;
    Neu private _token;
    uint256 private _ticketPrice;

    mapping(address => uint256) private totalTickets;
    mapping(address => uint256) private usedTickets;

    constructor(address server, Neu token, uint256 ticketPrice) {
        _server = server;
        _token = token;
        _ticketPrice = ticketPrice;
    }

    function buyTickets(address forUser, uint256 amount) public {
        _token.transferFrom(forUser, _server, amount * _ticketPrice);
        totalTickets[forUser] = totalTickets[forUser] + amount;
    }

    function useTicketsUpTo(uint256 ticketNumber) public returns (uint256 torn) {
        if (ticketNumber < totalTickets[msg.sender] || ticketNumber < usedTickets[msg.sender]) return 0;
        torn = ticketNumber - usedTickets[msg.sender];
        usedTickets[msg.sender] = ticketNumber;
    }

    function redeemVoucher(address forUser, uint256 tickets, uint8 v, bytes32 r, bytes32 s) public {
        assert(ecrecover(keccak256(abi.encodePacked(tickets, forUser)), v, r, s) == _server); // Check that the server has signed a message giving the user some tickets
        assert(tickets > totalTickets[forUser]);
        totalTickets[forUser] = tickets;
    }

    // View functions
    function getTotalTickets(address user) external view returns (uint256) {
        return totalTickets[user];
    }

    function getUsedTickets(address user) external view returns (uint256) {
        return usedTickets[user];
    }
}
