// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CommitReveal {
    uint8 public max = 100;

    struct Commit {
        bytes32 commitHash; // เก็บ hash ของ choice+salt
        uint64 blockNumber; // เก็บบล็อกที่ทำการ commit
        bool revealed; // ตรวจสอบว่าสถานะการเปิดเผยหรือไม่
    }

    mapping(address => Commit) public commits;

    event CommitHash(address sender, bytes32 commitHash, uint64 blockNumber);
    event RevealHash(address sender, bytes32 revealChoice, bytes32 revealSalt, uint random);

    // ฟังก์ชัน Commit สำหรับส่ง hash ของ choice + salt
    function commit(bytes32 commitHash) public {
        commits[msg.sender].commitHash = commitHash;
        commits[msg.sender].blockNumber = uint64(block.number);
        commits[msg.sender].revealed = false;
        emit CommitHash(msg.sender, commitHash, commits[msg.sender].blockNumber);
    }

    // ฟังก์ชัน Reveal สำหรับเปิดเผย choice และ salt
    function reveal(bytes32 revealChoice, bytes32 revealSalt) public {
        // ตรวจสอบว่าผู้เล่นยังไม่ได้ทำการ reveal
        require(!commits[msg.sender].revealed, "CommitReveal::reveal: Already revealed");

        // ตรวจสอบว่า hash (choice + salt) ตรงกับค่าที่ commit ไว้หรือไม่
        require(getCommitHash(revealChoice, revealSalt) == commits[msg.sender].commitHash, 
            "CommitReveal::reveal: Revealed data does not match commit");

        // ตรวจสอบว่า block ที่ทำการ reveal เกิดหลังจาก commit
        require(uint64(block.number) > commits[msg.sender].blockNumber, 
            "CommitReveal::reveal: Reveal and commit happened on the same block");

        // ตรวจสอบว่า block ที่ reveal ไม่เกินจาก block ที่กำหนดไว้
        require(uint64(block.number) <= commits[msg.sender].blockNumber + 250, 
            "CommitReveal::reveal: Revealed too late");

        // ดึงค่า blockhash ของ block ที่ commit เพื่อนำมาสร้างค่า random
        bytes32 blockHash = blockhash(commits[msg.sender].blockNumber);
        uint random = uint(keccak256(abi.encodePacked(blockHash, revealChoice, revealSalt))) % max;

        // ทำการ mark ว่า revealed แล้ว
        commits[msg.sender].revealed = true;
        emit RevealHash(msg.sender, revealChoice, revealSalt, random);
    }

    // ฟังก์ชันสำหรับสร้าง commit hash จาก choice และ salt
    function getCommitHash(bytes32 choice, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(choice, salt));
    }
}
