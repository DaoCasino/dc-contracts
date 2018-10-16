pragma solidity ^0.4.24;

import '../interfaces/IToken.sol';
import '../interfaces/IGameMarket.sol';
import '../interfaces/IPlatformFactory.sol';
import '../interfaces/IGameFactory.sol';
import './GameInstance.sol';
    
/**
 * @title Game Factory
 * @dev Creates and manages game instances
 */
contract GameFactory {

    /** @dev Contains info about game operator and game address */
    struct Game {
        address operator;
        address game;
    }

    /** @dev Emits when new game was created */
    event createGame(
        address indexed operator,
        address indexed game,
        address indexed proxy
    );

    /** @dev Example of token contract */
    IToken public token;

    /** @dev Example of GameMarket contract */
    IGameMarket public market;

    /** @dev Example of PlatformFactory contract */
    IPlatformFactory public platformFactory;

    /** @dev Example of ProxyFactory contract */
    IGameFactory public factory;

    /** @dev Stores game by its address */
    mapping(address => Game) public games;

    /**
     * @notice Initialize (ex-constructor)
	 * @param _token token contract address
	 * @param _platformFactory platform factory contract address
	 * @param _market Gamemarket contract address
	 */
    constructor (IToken _token, IPlatformFactory _platformFactory, IGameMarket _market) public {
        token           = _token;
        platformFactory = _platformFactory;
        market          = _market;
    }

    /**
    * @notice Verify operator's signature
	* @param _game Address of game
	* @param _bankrollReward Reward percent for bankroller
	* @param _platformReward Reward percent for platform
	* @param _referrerReward Reward percent for referrer
	*/
    function createInstance(address _game, uint _bankrollReward, uint _platformReward, uint _referrerReward) external returns (address _gameInstance) {
        require(market.isAcceptedByAddress(_game), "Game is not accepted");
        //require(platformFactory.isPlatform(msg.sender));
        address _developer     = market.getDeveloper(_game);
        uint256 _gameDevReward = market.getReward(_game);
        _gameInstance = new gameInstance(IPlatform(msg.sender), token, _game, _developer, _gameDevReward, _bankrollReward, _platformReward, _referrerReward);
        games[_game] = Game({operator: msg.sender, game: _game});
    }

}