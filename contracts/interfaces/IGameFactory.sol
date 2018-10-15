pragma solidity ^0.4.24;

interface IGameFactory {
    function createInstance(address _games, uint _bankrollReward, uint _platformReward, uint _refererReward) external returns (address _game);
}