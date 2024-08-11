# Intro
`Lottery.t.sol` 파일에 구현된 테스트케이스를 통과하도록 `Lottery.sol`에 컨트랙트를 구현하자.

Lottery.sol
```javascript
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
	function buy(uint16 number) external payable {}
	function draw() external {}
	function claim() external {}
}
```
# 함수 구현
## buy(number)
```javascript
uint256 public ticketPrice = 0.1 ether;
uint256 public drawTime;
mapping(uint16 => address[]) public ticketHolders;

constructor() {
	drawTime = block.timestamp + 24 hours;
}

function buy(uint16 number) external payable {
	require(msg.value == ticketPrice, "Incorrect ticket price");
	require(ticketHolders[number].length == 0 || ticketHolders[number][0] != msg.sender, "Duplicate ticket purchase");
	require(block.timestamp < drawTime, "already End of sell phase");
	ticketHolders[number].push(msg.sender);
}
```
`buy(number)`함수는 유저가 티켓값을 지불하고 번호를 구매하는 동작을 수행한다.
이때 티켓의 값은 `0.1 ether`이며, 응모 번호는 중복하여 구매할 수 없다. 또한, 게임이 시작되고 `24 hours`동안은 sell phase에 돌입하며, 24시간 이후에는 draw phase로 응모 번호를 구입할 수 없다.
## draw()
```javascript
uint16 public winningNumber;
mapping(address => bool) winner;
uint256 payout;
bool drawed = false;

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
```
`draw()`함수는 승자를 정하고 금액을 배분하는 동작을 수행한다.
`draw phase`에만 `draw()`를 수행할 수 있으며, 단 한번만 수행할 수 있다. `block.timestamp`를 통해 승리 번호를 정하고, `winner`변수에 승자를 저장하며, `payout`에 당첨 금액을 저장한다.
## claim()
```javascript
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
```
`claim()`함수는 승자에게 당첨금액을 전달하는 동작을 수행한다.
`draw phase`이후에 수행할 수 있으며, 여러번 호출될 수 있다. 승자가 `claim()`함수를 호출할 경우, 당첨금액을 나누어 주지만, 승자가 아닌 사람이 호출하면 아무 일도 일어나지 않는다. 만약, 승자가 아무도 없을 경우 `drawTime`과 `drawed`함수를 조정하여 새로운 sell phase를 시작하고, 다음 승자에게 당첨금을 몰아준다.
## fallback()
```javascript
fallback() external payable {}
```
이더리움의 수령을 위해 `fallback()`함수를 구현한다.
# Lottery.sol
```javascript
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
```