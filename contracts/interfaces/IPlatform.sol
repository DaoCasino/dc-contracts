pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

interface IPlatform {
    function deposit(address _player, uint _value) external returns(bool);
    function payout(address _player, uint _value) external;
    function getService(address _player) external constant returns(address _operator, address _referrer);
    function getStatus(address _game) external view returns(bool status);
    function getMaxAmount(address _player) external view returns(uint);
}