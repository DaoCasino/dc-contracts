pragma solidity ^0.4.24;

interface IPlatformFactory {
    function isPlatform(address _casino) external returns(bool);
}