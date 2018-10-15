pragma solidity ^0.4.24;

interface IKYCOperator {
    function checkSig(address _user, bytes _sig) external view returns (bool);
}