pragma solidity ^0.4.24;

import '../lib/Utils.sol';

contract KYCOperator  {   

    constructor () public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;


    mapping(address => bool) public operators;

    /// @notice Add operator to registry
	/// @param _operator Address of operator 
    function addOperator(address _operator) public onlyOwner {
        operators[_operator] = true;
    }
    
    /// @notice Verify operator's signature
	/// @param _user Address of user 
	/// @param _signature Address of user 
    function checkSig(address _user, bytes _signature) external view returns (bool) {
        address _signer = Utils.recoverSigner(keccak256(abi.encodePacked(_user)), _signature);
        return operators[_signer];
    }
}