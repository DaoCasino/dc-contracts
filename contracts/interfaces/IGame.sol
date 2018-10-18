pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import '../gameCore/GameObject.sol';

contract IGame is GameObject {
    function game(gameData memory _gameData, uint[] memory _bets, uint[] memory _randoms) public view returns (int256[2]);
    function checkGameData(gameData memory _gameData, uint[] memory _bets) public view returns (bool);
    function getProfit(gameData memory _gameData, uint[] memory _bets) public pure returns (uint256);
}