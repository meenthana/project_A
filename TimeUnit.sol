// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;

contract BettingGame {
    
    // Struct สำหรับเก็บข้อมูลผู้เล่น
    struct Player {
        address payable playerAddress;
        uint256 amount; // จำนวนเงินที่ลงขัน
        bytes32 choiceHash; // เก็บ Hash ของตัวเลือก (เช่น หิน, กรรไกร, กระดาษ)
        bool hasSubmitted; // ตรวจสอบว่าผู้เล่นได้ส่งตัวเลือกหรือยัง
    }
    
    // ผู้เล่น 0 และผู้เล่น 1
    Player public player0;
    Player public player1;
    
    // เก็บเวลาเริ่มต้น
    uint256 public startTime;
    
    // ระยะเวลาที่รอผู้เล่นส่งตัวเลือก
    uint256 public submitTimeout = 10 minutes; // สามารถปรับเวลาได้ตามต้องการ
    
    // สถานะของเกม
    bool public gameStarted = false;
    bool public gameLocked = false;

    // ฟังก์ชันสำหรับผู้เล่น 0 ในการลงขัน
    function placeBetPlayer0() public payable {
        require(!gameStarted, "Game already started");
        require(msg.value > 0, "Bet amount must be greater than zero");

        player0 = Player(payable(msg.sender), msg.value, "", false);
        startTime = block.timestamp;
        gameStarted = true;
    }

    // ฟังก์ชันสำหรับผู้เล่น 1 ในการลงขัน
    function placeBetPlayer1() public payable {
        require(gameStarted, "Game has not started yet");
        require(!gameLocked, "Game is locked, too late to join");
        require(msg.value == player0.amount, "Must match player 0's bet");

        player1 = Player(payable(msg.sender), msg.value, "", false);
        gameLocked = true; // ล็อกเกมหลังจากผู้เล่น 1 ลงขันแล้ว
    }

    // ฟังก์ชันสำหรับส่งตัวเลือกของผู้เล่น (ใช้ hash เพื่อปกปิดตัวเลือกก่อนเปิดเผยจริง)
    function submitChoice(bytes32 choiceHash) public {
        require(gameStarted, "Game has not started yet");
        require(gameLocked, "Both players must have placed their bets");
        
        if (msg.sender == player0.playerAddress) {
            require(!player0.hasSubmitted, "Player 0 has already submitted a choice");
            player0.choiceHash = choiceHash;
            player0.hasSubmitted = true;
        } else if (msg.sender == player1.playerAddress) {
            require(!player1.hasSubmitted, "Player 1 has already submitted a choice");
            player1.choiceHash = choiceHash;
            player1.hasSubmitted = true;
        } else {
            revert("Invalid player");
        }
    }

    // ฟังก์ชันสำหรับตรวจสอบการหมดเวลาในการส่งตัวเลือก
    function checkSubmitTimeout() public {
        require(gameStarted, "Game has not started yet");
        require(gameLocked, "Game must be locked for timeout to apply");
        
        if (block.timestamp >= startTime + submitTimeout) {
            // หากผู้เล่นคนใดคนหนึ่งไม่ยอมส่งตัวเลือกภายในเวลาที่กำหนด
            if (!player0.hasSubmitted && !player1.hasSubmitted) {
                // หากไม่มีใครส่งตัวเลือกเลย คืนเงินทั้งสองคน
                player0.playerAddress.transfer(player0.amount);
                player1.playerAddress.transfer(player1.amount);
            } else if (!player0.hasSubmitted) {
                // หากผู้เล่น 0 ไม่ส่งตัวเลือก ผู้เล่น 1 ชนะและได้เงินทั้งหมด
                player1.playerAddress.transfer(address(this).balance);
            } else if (!player1.hasSubmitted) {
                // หากผู้เล่น 1 ไม่ส่งตัวเลือก ผู้เล่น 0 ชนะและได้เงินทั้งหมด
                player0.playerAddress.transfer(address(this).balance);
            }
            // รีเซ็ตสถานะของเกมหลังจากการคืนเงินหรือการตัดสิน
            resetGame();
        }
    }

    // ฟังก์ชันสำหรับรีเซ็ตสถานะของเกม
    function resetGame() internal {
        gameStarted = false;
        gameLocked = false;
        delete player0;
        delete player1;
        startTime = 0;
    }
}
