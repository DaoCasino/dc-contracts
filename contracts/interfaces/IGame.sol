pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import '../gameCore/GameObject.sol';

contract IGame is GameObject {
    function game(gameData _gameData, uint[] _bets, uint _randoms) public view returns (int256[2]);
    function checkGameData(gameData _gameData, uint[] _bets) public view returns (bool);
    function getProfit(gameData _gameData, uint[] _bets) public pure returns (uint256);
}