pragma solidity ^0.4.24;

import '../lib/SafeMath.sol';
import '../interfaces/Interfaces.sol';

/**
* @title Simple game
* @dev Example of simple game
*/
contract SimpleGame {

    using SafeMath for uint;

    /** @dev Contains info about min and max bets */
    struct Config {
        uint minBet;
        uint maxBet;
    }

    Config config = Config({
        minBet: 1,
        maxBet: 100 ether
        });

    constructor () public {

    }

    /**
     @notice interface for check game data
     @param _gameData Player's game data
     @param _bet Player's bet
     @return result boolean
     */
    function checkGameData(uint[] _gameData, uint _bet) public view returns (bool) {
        uint playerNumber = _gameData[0];
        require(_bet >= config.minBet && _bet <= config.maxBet);
        require(playerNumber == 1 || playerNumber == 2);
        return true;
    }

    /**
    @notice interface for game logic
    @param _gameData Player's game data
    @param _bet Player's bet
    @param _sigseed random seed for generate rnd
    */
    function game(uint[] _gameData, uint _bet, bytes _sigseed) external view returns(bool _win, uint _amount) {
        checkGameData(_gameData, _bet);
        uint _min = 1;
        uint _max = 2;
        uint _rndNumber = generateRnd(_sigseed, _min, _max);
        //gameData[0] - player number
        uint _playerNumber = _gameData[0];
        uint _profit = getProfit(_gameData, _bet);

        // Game logic
        if (_playerNumber == _rndNumber) {
            // player win profit
            return(true, _profit);
        } else {
            // player lose bet
            return(false, _bet);
        }
    }

    /**
    @notice profit calculation
    @param _gameData Player's game data
    @param _bet Player's bet
    @return profit
    */
    function getProfit(uint[] _gameData, uint _bet) public pure returns(uint _profit) {
        uint _playerNumber = _gameData[0];
        // Player win x2
        _profit = _bet.mul(2);
    }

    /**
    @notice Generate random number from sig
    @param _sigseed Sign hash for creation random number
    @param _min Minimal random number
    @param _max Maximal random number
    @return random number
    */
    function generateRnd(bytes _sigseed, uint _min, uint _max) public pure returns(uint) {
        require(_max < 2**128);
        return uint256(keccak256(_sigseed)) % (_max.sub(_min).add(1)).add(_min);
    }

    /**
     * @return Returns min and max bets for game
     */
    function getConfig() public view returns(uint _minBet, uint _maxBet) {
        _minBet = config.minBet;
        _maxBet = config.maxBet;
    }

}
