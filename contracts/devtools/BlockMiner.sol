pragma solidity ^0.4.24; 

// used to "waste" blocks for truffle tests
contract BlockMiner {
    uint256 blocksMined;

    constructor() {
        blocksMined = 0;
    }

    function mine() public {
       blocksMined += 1;
    }
}