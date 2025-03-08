// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RPSLS {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping(address => uint) public player_choice; // 0 - Rock, 1 - Paper, 2 - Scissors, 3 - Lizard, 4 - Spock
    mapping(address => bool) public player_not_played;
    address[] public players;
    uint public numInput = 0;

    address[4] allowedPlayers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    function isAllowed(address player) internal view returns (bool) {
        for (uint i = 0; i < allowedPlayers.length; i++) {
            if (allowedPlayers[i] == player) {
                return true;
            }
        }
        return false;
    }

    function addPlayer() public payable {
        require(isAllowed(msg.sender), "Not an allowed player");
        require(numPlayer < 2, "Game already has two players");
        if (numPlayer > 0) {
            require(msg.sender != players[0], "Same player cannot join twice");
        }
        require(msg.value == 1 ether, "Entry fee is 1 ether");
        
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    function input(uint choice) public {
        require(numPlayer == 2, "Waiting for players");
        require(player_not_played[msg.sender], "Player already played");
        require(choice >= 0 && choice <= 4, "Invalid choice");
        
        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;
        
        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if ((p0Choice == 0 && (p1Choice == 2 || p1Choice == 3)) || 
            (p0Choice == 1 && (p1Choice == 0 || p1Choice == 4)) || 
            (p0Choice == 2 && (p1Choice == 1 || p1Choice == 3)) || 
            (p0Choice == 3 && (p1Choice == 1 || p1Choice == 4)) || 
            (p0Choice == 4 && (p1Choice == 0 || p1Choice == 2))) {
            account0.transfer(reward);
        } else if ((p1Choice == 0 && (p0Choice == 2 || p0Choice == 3)) || 
                   (p1Choice == 1 && (p0Choice == 0 || p0Choice == 4)) || 
                   (p1Choice == 2 && (p0Choice == 1 || p0Choice == 3)) || 
                   (p1Choice == 3 && (p0Choice == 1 || p0Choice == 4)) || 
                   (p1Choice == 4 && (p0Choice == 0 || p0Choice == 2))) {
            account1.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        _resetGame();
    }

    function _resetGame() private {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
    }
}
