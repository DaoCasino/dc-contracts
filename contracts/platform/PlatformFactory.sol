pragma solidity ^0.4.24;

import './PlatformManager.sol';

/**
* @title Platform Factory
* @dev Factory for platform contract. Creates instances of Platform Manager and proxies to them at once
*/
contract PlatformFactory {

    /** @dev Example of token contract */
    IToken token;

    /**
    * @dev Emits when new platform instance was created
    */
    event Create (
        address indexed platformInstance
    );

    /**
    @notice Initialize (ex-constructor)
    @param _token token contract address
    */
    constructor (IToken _token) public {
        token = _token;
    }

    /**
    * @dev Stores active platforms
    */
    mapping(address => bool) private platforms;
    
    /**
    @notice Create platform instance
    @return platform instance contract address
    */
    function createPlatform() external returns(address _platform) {
        // TODO validation!
        _platform = new PlatformManager(token);
        platforms[_platform] = true;
        emit Create(_platform);
    }

    /**
    @notice Check platform address
    @param _platform platrform contract address
    @return result
    */
    function isPlatform(address _platform) external view returns(bool) {
        return platforms[_platform];
    }
    
}