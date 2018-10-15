pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

contract GameObject {
    
    struct gameData {
        uint256      playerNumber;
        uint256[2][] randomRanges;
        bytes32      seed;
    }

    function hashGameData(gameData _object) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            _object.playerNumber,
            _object.randomRanges,
            _object.seed
        ));
    }

}