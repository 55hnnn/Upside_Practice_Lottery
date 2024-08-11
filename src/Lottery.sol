// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
    uint256 public ticketPrice = 0.1 ether;
    uint256 public drawTime;
    uint16 public winningNumber;
    mapping(uint16 => address[]) public ticketHolders;
    mapping(address => bool) winner;
    uint256 payout;

    bool drawed = false;
    
    constructor() {
        drawTime = block.timestamp + 24 hours;
    }

    function buy(uint16 number) external payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(ticketHolders[number].length == 0 || ticketHolders[number][0] != msg.sender, "Duplicate ticket purchase");
        require(block.timestamp < drawTime, "already End of sell phase");
        ticketHolders[number].push(msg.sender);
    }

    function draw() external {
        require(block.timestamp >= drawTime, "Cannot draw before the end of sell phase");
        require(drawed == false, "already drawed");
        drawed = true;
        winningNumber = uint16(uint256(keccak256(abi.encodePacked(block.timestamp))) % 10000);
        for (uint256 i = 0; i < ticketHolders[winningNumber].length; i++) {
            winner[ticketHolders[winningNumber][i]] = true;
        }
        if (ticketHolders[winningNumber].length > 0) {
            payout = address(this).balance / ticketHolders[winningNumber].length;
        }
    }

    function claim() external {
        require(block.timestamp >= drawTime, "Sell phase is in progress");
        if (ticketHolders[winningNumber].length < 1){
            drawTime = block.timestamp + 24 hours;
            drawed = false;
        }
        else if (winner[msg.sender] == true){
            payable(msg.sender).call{value:payout}("");
        }
        else return;
    }

    fallback() external payable {}
}