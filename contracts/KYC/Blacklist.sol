pragma solidity ^0.4.24;

contract Blacklist {

    constructor(address _owner) public {
        owner = _owner;
    }    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;
    
    mapping(address => bool) public blockedUser;

	/// @notice Add user to blacklist
	/// @param _user Address of user   
    function addUser(address _user) public onlyOwner {
        blockedUser[_user] = true;
    }

	/// @notice Delete user to blacklist
	/// @param _user Address of user 
    function delUser(address _user) public onlyOwner {
        blockedUser[_user] = false;
    }

	/// @notice Adds user to blacklist
	/// @param _user Address of user 
    function checkUser(address _user) public view returns (bool) {
        return blockedUser[_user];
    }

}