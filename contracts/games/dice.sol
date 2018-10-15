pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import '../lib/SafeMath.sol';
import '../interfaces/IGame.sol';
import '../gameCore/Signidice.sol';

/**
* @title Dice game
* @dev Example of dice game
*/
contract Dice is Signidice, IGame {

    using SafeMath for uint;

    constructor () public {

    }

   /** 
    @notice interface for check game data
    @param _gameData Player's game data
    @param _bets Player's bets
    @return result boolean
    */
    function checkGameData(gameData _gameData, uint[] _bets) public view returns (bool) {
        return true;
    }

    function resolveGame(gameData _gameData, uint[] _bets, bytes _rnd) external view returns (int256[2]) {   
        require(checkGameData(_gameData, _bets));
        uint[] memory _rndNumber = generateRnd(_gameData.randomRanges, _rnd);
        return game(_gameData, _bets, _rndNumber);
    }

    function game(gameData _gameData, uint[] _bets, uint[] _randoms) pure returns (int256[2]) {
        uint256 randomNumber = _randoms[0];
        int256 playerProfit;
        int256 bankrollerProfit;
        
        if (_gameData.playerNumber >= randomNumber) {
            // player win 
            uint256 profit = getProfit(_gameData, _bets); 
            playerProfit     =  int256(profit);
            bankrollerProfit = -int256(profit);
        } else {
            // player lose
            playerProfit     = -int(_bets[0]);
            bankrollerProfit =  int(_bets[0]);
        }
        return([playerProfit, bankrollerProfit]);
    }

    function getProfit(gameData _gameData, uint[] _bets) public pure returns(uint _profit) {
        uint _playerNumber = _gameData.playerNumber;
        uint _bet = _bets[0];
        _profit = (_bet.mul(uint(65535).mul(10000).div(_playerNumber)).div(10000)).sub(_bet);
    }

}
