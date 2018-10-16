pragma solidity ^0.4.24;

import '../interfaces/IToken.sol';
import '../interfaces/IGameFactory.sol';
import '../interfaces/IKYCOperator.sol';
import '../lib/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/AddressUtils.sol';
/**
* @title Platform Manager
* @dev Contain all functions for platform management
*/
contract PlatformManager is Ownable {

    /** @dev Emits when new game was added */
    event GameAdded(address indexed gameContract);

    using SafeMath for uint;
    using AddressUtils for address;

    uint256 public minimum = 100 ether;

    /** @dev Example of token contract */
    IToken public token;

    /** @dev Example of KYC Operator contract */
    IKYCOperator public KYC;

    /** @dev Stores addresses of managers */
    mapping(address => bool) public isManager;

    /** @dev Stores game data by its address */
    mapping(address => Status) public gameStatus;

    /** @dev Stores user data by its address */
    mapping(address => User) public users;

    /** @dev Contains possible states of game */
    enum Status {unreg, active, stoped}

    /** @dev Contains different data about user */
    struct User {
        Status  status;
        uint256 maxDeposit;
        address referrer;
        uint256 totalBet;
        uint256 sessionCount;
    }

    /** @dev Provides only-manager functionality */
    modifier onlyManager() {
        require(isManager[msg.sender] || msg.sender == owner, 'invalid sender');
        _;
    }

    /** @dev Provides only-game functionality */
    modifier onlyGame() {
        require(gameStatus[msg.sender] == Status.active, 'Invalid game address');
        _;
    }

    /**
     * @dev Uses to initialize the proxy
     * @param _token Address of the token contract
     */
    constructor (IToken _token) public {
        owner = tx.origin;
        token = _token;
    }

    /**
     * @return Returns address of the owner
     */
    function rewardAddress() external view returns(address) {
        return owner;
    }

    /**
     * @dev Transfers allowed tokens to platform as deposit
     * @param _player Address of player who stores his funds
     * @param _value Amount of tokens to store
     */
    function deposit(address _player, uint _value) external onlyGame returns(bool result) {
        require(getMaxAmount(_player) >= _value, 'invalid value');
        require(token.transferFrom(_player, msg.sender, _value), 'approve fail');
        if (checkRegBonus(_player, _value)) {
            token.transfer(_player, regBonus.amount);
        }
        return true;
    }

    /**
     * @dev Uses for payout to player. Can be called only from game address
     * @param _player Address of the player
     * @param _value Amount for the payout
     */
    function payout(address _player, uint _value) external onlyGame {
        users[_player].totalBet = (users[_player].totalBet).add(_value);
        users[_player].sessionCount = (users[_player].sessionCount).add(1);
    }

    /**
     * @param _player Address of the player
     * @return Returns the refferer address
     */
    function getReferrer(address _player) external view  returns(address) {
        return users[_player].referrer;
    }

    /**
     * @dev Adds manager permission to the player
     * @param _player Address of the player
     */
    function regManager(address _player) external onlyOwner {
        isManager[_player] = true;
    }

    /**
     * @dev Revoke manager permission from the player
     * @param _player Address of the player
     */
    function delManager(address _player) external onlyOwner {
        isManager[_player] = false;
    }

    /**
     * @dev Registrate address as user
     * @param _user Address of the user
     * @param _maxDeposit Max deposit allowed for the user
     * @param _cpa Cost per action
     * @param _KYCSig Signature from KYC Provider
     */
    function regUser(address _user, uint _maxDeposit, address _referrer, bool _cpa, bytes _KYCSig) public onlyManager {
        require(users[_user].status == Status.unreg);
        //require(KYC.checkSig(_user, _KYCSig));
        users[_user].status         = Status.active;
        users[_user].maxDeposit     = _maxDeposit;
        if (_cpa) {
            users[_user].referrer = owner;
            cpaReferrer[_user] = _referrer;
        } else {
           users[_user].referrer = _referrer; 
        }
    }

    /**
     * @param _user Address of the user
     * @return User data
     */
    function getUser(address _user) public view returns(Status, uint, address) {
        return(users[_user].status, users[_user].maxDeposit, users[_user].referrer);
    }

    /**
     * @dev Sets user status as stopped
     * @param _user Address of the user
     */
    function stopUser(address _user) public onlyManager {
        require(users[_user].status == Status.active);
        users[_user].status = Status.stoped;
    }

    /**
     * @dev Sets user status as active
     * @param _user Address of the user
     */
    function activateUser(address _user) public onlyManager {
        require(users[_user].status == Status.stoped);
        users[_user].status = Status.active;
    }


    /**
     * @dev Sets user status as stopped
     * @param _user Address of the user
     * @param _newMaxDeposit Max allowed user deposit
     */
    function setMaxAmount(address _user, uint _newMaxDeposit) public onlyManager {
        require(users[_user].status == Status.active);
        users[_user].maxDeposit = _newMaxDeposit;
    }


    /**
     * @param _player Address of the player
     * @return Max allowed user deposit
     */
    function getMaxAmount(address _player) public view  returns(uint) {
        if (users[_player].status == Status.unreg) {
            return minimum;
        }
        return users[_player].maxDeposit;
    }

    /**
     * @dev Regs new game
     * @param _gameFactory Address of the GameFactory contract
     * @param _gameLogic Address of contract where game logic is stored
     * @param _bankrollReward Reward for the bankroller
     * @param _platformReward Reward for the platform
     * @param _refererReward Reward for the refferer
     * @return Address of created contract
     */
    function regGame(address _gameFactory, address _gameLogic, uint _bankrollReward, uint _platformReward, uint _refererReward) external returns(address) {
        address _game = IGameFactory(_gameFactory).createInstance(_gameLogic, _bankrollReward, _platformReward, _refererReward);
        gameStatus[_game] = Status.active;
        emit GameAdded(_game);
        return _game;
    }

    /**
     * @dev Returns status of the game
     * @param _game Address of the game
     * @return Status of the game
     */
    function getStatus(address _game) public view  returns(Status) {
        return gameStatus[_game];
    }

    /**
     * @dev Sets game status to active
     * @param _game Address of the game
     */
    function activateGame(address _game) external onlyOwner {
        gameStatus[_game] = Status.active;
    }

    /**
     * @dev Sets game status to stopped
     * @param _game Address of the game
     */
    function stopGame(address _game) external onlyManager {
        gameStatus[_game] = Status.stoped;
    }

    /** @dev Contains CPA data */
    struct CPAConfig {
        uint256 totalBet;
        uint256 sessionCount;
        uint256 Bonus;
        uint256 Bank;
    }

    struct REGConfig {
        uint256 amount;
        uint256 nimSessionCount;
        uint256 minBonusDeposit;
    }

    REGConfig regBonus;
    CPAConfig cpaConfig;

    mapping(address => address) public cpaReferrer;

    function CPAInit(uint256 _totalBet, uint256 _sessionCount, uint256 _bonus, uint256 _bank) external onlyManager {
        // TODO require bank || time || ???
        cpaConfig = CPAConfig(_totalBet, _sessionCount, _bonus, _bank);
    }

    /**
     * @dev Uses for getting CPA bonus from player
     * @param _player Player address
     */
    function getCPABonus(address _player) external  {
        require(checkCPABonus(_player));
        token.transfer(cpaReferrer[_player], cpaConfig.Bonus);
        cpaConfig.Bank = cpaConfig.Bank.sub(cpaConfig.Bonus);
        cpaReferrer[_player] = address(0);
    }

    /**
     * @dev Checks if player satisfies the conditions to get CPA bonus
     * @param _player Player address
     * @return true if player satisfies the conditions
     */
    function checkCPABonus(address _player) public view returns(bool) {
        require(cpaReferrer[_player] != address(0));
        require(users[_player].totalBet >= cpaConfig.totalBet);
        require(users[_player].sessionCount >= cpaConfig.sessionCount);
        require(cpaConfig.Bank >= cpaConfig.Bonus);
        return true;
    }

    function checkRegBonus(address _player, uint _value) internal view returns(bool) {
        if (users[_player].sessionCount == regBonus.nimSessionCount && _value >= regBonus.minBonusDeposit) {
            return true;
        }
        return false;
    }
}
