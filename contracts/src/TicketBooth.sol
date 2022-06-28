// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Neu.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract TicketBooth {
    using ECDSA for bytes32;

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

    function buyTickets(uint256 amount) public {
        _token.transfer(_server, amount * _ticketPrice);
        totalTickets[msg.sender] = totalTickets[msg.sender] + amount; 
    }

    function useTickets(uint256 amount) public {
        assert(usedTickets[msg.sender] + amount <= totalTickets[msg.sender]);
        usedTickets[msg.sender] = usedTickets[msg.sender] + amount;
    }

    function redeemVoucher(uint256 tickets, bytes memory signature) public {
        assert(keccak256(abi.encodePacked(tickets, msg.sender)).recover(signature) == _server); // Check that the server has signed a message giving the msg.sender some tickets
        assert(tickets > totalTickets[msg.sender]);
        totalTickets[msg.sender] = tickets;
    }

    // View functions
    function getTotalTickets(address user) public view returns (uint256) {
        return totalTickets[user];
    }

    function getUsedTickets(address user) public view returns (uint256) {
        return usedTickets[user];
    }
}
