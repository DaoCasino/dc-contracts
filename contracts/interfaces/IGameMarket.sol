pragma solidity ^0.4.24;

interface IGameMarket {
    function getDeveloper(address gameContract) external view returns (address);
    function isAccepted(uint id) external view returns (bool);
    function isAcceptedByAddress(address gameContract) external view returns (bool);
    function getReward(address gameContract) external view returns (uint);
}