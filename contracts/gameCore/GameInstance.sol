pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import {IToken, IPlatform, IGame} from '../interfaces/interfaces.sol';
import '../lib/SafeMath.sol';
import '../lib/Utils.sol';
import './GameObject.sol';
import './Signidice.sol';

/**
 * @title Game instance
 */
contract gameInstance is Signidice, GameObject {

    /** @dev Emits when channel was created, updated or closed */
    event logChannel(
        string  action,
        bytes32 channelId
    );

    using SafeMath for uint;

    /** @dev Address of the developer */
    address   public developer;

    /** @dev Time pointer for some commands */
    uint256   public safeTime = 120;

    /** @dev Time, after that only closeByDispute can be called */
    uint256   public sessionTime = 150;

    /** @dev time to live of signature */
    uint256   public ttl = 20;

    /** @dev Example of token contract */
    IToken    public token;

    /** @dev Example of platform contract */
    IPlatform public platform;

    /** @dev Example of game contract */
    IGame     public gameLogic;

    /** @dev Example of Config structure */
    Config    public config;

    /** @dev Contains info about rewards for each participant */
    struct Config {
        uint256 gameDevReward;
        uint256 bankrollReward;
        uint256 platformReward;
        uint256 refererReward;
    }

    /** @dev Contains channel data */
    struct Channel {
        Status  status;
        address player;
        address bankroller;
        uint256    playerBalance;
        uint256    bankrollerBalance;
        uint256    totalBet;
        uint256    session;
        uint256    endBlock;
        bytes  gameData;
        bytes32 RSAHash;
    }

    /** @dev Contains dispute data */
    struct Dispute {
        uint[]   disputeBets;
        gameData disputeGameData;
    }

    /** @dev Contains possible statuss of channel */
    enum Status {unused, open, close, dispute}

    /** @dev Contains channel data by its id */
    mapping(bytes32 => Channel) public channels;

    /** @dev Contains dispute data by its id */
    mapping(bytes32 => Dispute) public disputes;

    /**
    @notice constructor
    */
    constructor (
        IPlatform _platform,
        IToken _token,
        address _game,
        uint256 _gameDevReward,
        uint256 _bankrollReward,
        uint256 _platformReward,
        uint256 _refererReward
    )
        public
    {
        require(_gameDevReward.add(_bankrollReward).add(_platformReward).add(_refererReward) == uint(100), 'invalid percent');
        token     = IToken(_token);
        platform  = IPlatform(_platform);
        gameLogic = IGame(_game);
        developer = address(0);
        config.gameDevReward  = _gameDevReward;
        config.bankrollReward = _bankrollReward;
        config.platformReward = _platformReward;
        config.refererReward  = _refererReward;
    }

    modifier active(Channel _channel) {
        require(
            msg.sender == _channel.player ||
            msg.sender == _channel.bankroller,
            'invalid sender'
            );
        require(
            _channel.endBlock > block.number && 
            ((_channel.status == Status.open) || (_channel.status == Status.dispute)),
            'invalid channel state'
            );
        _;
    }

    function openChannel(
        address[2] _users,
        uint256[2] _balances,
        uint256    _openingBlock,
        bytes      _data,
        bytes32    _RSAfingerprint,
        uint8[2]   _v,
        bytes32[2] _r, 
        bytes32[2] _s 
    )
        external
        returns(bytes32 _id)
    {
        _id = keccak256(abi.encodePacked(address(this), _users, _openingBlock));
        
        require(
            checkOpenChannel(_users, _balances, _openingBlock, _data, _RSAfingerprint, _v, _r, _s),
            'invalid check'
            );
        
        require(
            platform.deposit(_users[0], _balances[0]) && 
            platform.deposit(_users[1], _balances[1]), 
            'fail deposit'
            );
        
        Channel memory _channel = Channel({
            status            : Status.open,
            player            : _users[0],
            bankroller        : _users[1],
            playerBalance     : _balances[0],
            bankrollerBalance : _balances[1],
            totalBet          : uint(0),
            session           : uint(0),
            endBlock          : block.number.add(sessionTime),
            gameData          : _data,
            RSAHash           : _RSAfingerprint
            });

        channels[_id] = _channel;

        emit logChannel("open channel", _id);
    }

    
    function checkOpenChannel(
        address[2] _users,
        uint256[2] _balances,
        uint256       _openingBlock,
        bytes     _gameData,
        bytes32    _RSAfingerprint,
        uint8[2]   _v,
        bytes32[2] _r, 
        bytes32[2] _s 
    )
        public view returns (bool)
    {
        bytes32 _id = keccak256(abi.encodePacked(address(this), _users, _openingBlock));
        require(
            channels[_id].status == Status.unused, 
            'Used channel id');
        require(
            _openingBlock.add(ttl) >= block.number,
            'the signature is outdated'
            );
        bytes32 _hash = keccak256(abi.encodePacked(address(this), _users, _balances, _openingBlock, _gameData, _RSAfingerprint));
        Utils.checkDoubleSignature(_users, _hash, _v, _r, _s);
        return true;
    }

    /**
    @notice Update the status of the channel
    @param _id Unique channel identifier
    @param _playerBalance The player's account balance in the channel
    @param _bankrollerBalance The bankroller's account balance in the channel
    @param _session Number of the game session
    @param _sign Signature from the player or bankroller
    */
    function updateChannel(
        bytes32 _id,
        uint256 _playerBalance,
        uint256 _bankrollerBalance,
        uint256 _totalBet,
        uint256 _session,
        bytes _sign
    )
    public
    {
        Channel storage _channel = channels[_id];
        checkUpdateChannel(_id, _playerBalance, _bankrollerBalance, _totalBet, _session, _sign);

        if (_channel.endBlock.sub(block.number) < safeTime) {
            _channel.endBlock = block.number.add(safeTime);
        }

        _channel.session           = _session;
        _channel.playerBalance     = _playerBalance;
        _channel.bankrollerBalance = _bankrollerBalance;
        _channel.totalBet          = _totalBet;

        if (_channel.status == Status.dispute) {
            _channel.status = Status.open;
            delete disputes[_id];
        }

        emit logChannel("update channel", _id);
        checkGameOver(_id);
    }


    /**
    @notice Checks data for update the status of the channel
    @param _id Unique channel identifier
    @param _playerBalance The player's account balance in the channel
    @param _bankrollerBalance The bankroller's account balance in the channel
    @param _session Number of the game session
    @param _sign Signature from the player or bankroller
    */
    function checkUpdateChannel(
        bytes32 _id,
        uint256 _playerBalance,
        uint256 _bankrollerBalance,
        uint256 _totalBet,
        uint256 _session,
        bytes _sign
    )
    public view returns (bool)
    {
        Channel storage _channel = channels[_id];
        Utils.checkSigner(msg.sender, _channel.player, _channel.bankroller, keccak256(abi.encodePacked(_id, _playerBalance, _bankrollerBalance, _totalBet, _session)), _sign);
        require(
            _channel.session < _session,
            'outdated session'
            );
        require(
            _playerBalance.add(_bankrollerBalance) == _channel.playerBalance.add(_channel.bankrollerBalance),
            'invalid new balance'
            );
        return true;
    }

    /**
    @notice Closing of the channel by consent of the parties
    @param _id Unique channel identifier
    @param _playerBalance The player's account balance in the channel
    @param _bankrollerBalance The bankroller's account balance in the channel
    @param _session Number of the game session
    @param _sign Signature from the player or bankroller
    */
    function closeByConsent(
        bytes32 _id,
        uint256 _playerBalance,
        uint256 _bankrollerBalance,
        uint256 _totalBet,
        uint256 _session,
        bytes _sign
    )
    public active(channels[_id])
    {
        Channel storage _channel = channels[_id];
        checkCloseByConsent(_id, _playerBalance, _bankrollerBalance, _totalBet, _session, _sign);
        _channel.playerBalance     = _playerBalance;
        _channel.bankrollerBalance = _bankrollerBalance;
        _channel.session           = _session;
        _channel.totalBet          = _totalBet;

        emit logChannel("close by consent", _id);
        closeChannel(_id);
    }

    /**
    @notice Checks data for closing of the channel by consent of the parties
    @param _id Unique channel identifier
    @param _playerBalance The player's account balance in the channel
    @param _bankrollerBalance The bankroller's account balance in the channel
    @param _session Number of the game session
    @param _sign Signature from the player or bankroller
    */
    function checkCloseByConsent(
        bytes32 _id,
        uint256 _playerBalance,
        uint256 _bankrollerBalance,
        uint256 _totalBet,
        uint256 _session,
        bytes _sign
    )
    public view returns (bool)
    {
        Channel storage _channel = channels[_id];
        require(
            _playerBalance.add(_bankrollerBalance) == _channel.playerBalance.add(_channel.bankrollerBalance),
            'invalid new balance'
            );
        bytes32 _hash = keccak256(abi.encodePacked(_id, _playerBalance, _bankrollerBalance, _totalBet, _session, true));
        Utils.checkSigner(msg.sender, _channel.player, _channel.bankroller, _hash, _sign);
        return true;
    }

    /**
    @notice Closing the channel after the time has elapsed
    @param _id Unique channel identifier
    */
    function closeByTime(bytes32 _id) external {
        Channel storage _channel = channels[_id];
        
        require(
            _channel.endBlock < block.number,
            'invalid time'
            );
        
        if (_channel.status == Status.dispute) {
            closeByDispute(_id);
            return;
        }

        emit logChannel("close by time", _id);
        closeChannel(_id);
    }

    /**
    @notice Closing the channel after the time with dispute
    @param _id Unique channel identifier
    */
    function closeByDispute(bytes32 _id) internal {
        Channel storage _channel = channels[_id];
        Dispute storage _dispute = disputes[_id];
        uint256 _profit = gameLogic.getProfit(_dispute.disputeGameData, _dispute.disputeBets);
        _channel.bankrollerBalance = _channel.bankrollerBalance.sub(_profit);
        _channel.playerBalance     = _channel.playerBalance.add(_profit);
        emit logChannel("close by dispute", _id);
        closeChannel(_id);
    }

    /**
    @notice Check and close the channel at zero or min balance
    @param _id Unique channel identifier
    */
    function checkGameOver(bytes32 _id) internal {
        if (channels[_id].playerBalance < 0 || channels[_id].bankrollerBalance == 0) {
            emit logChannel("game over", _id);
            closeChannel(_id);
        }
    }

    /**
    @notice To open a dispute 
    @param _id Unique channel identifier
    @param _session Number of the game session
    @param _disputeSeed seed for generate random
    @param _disputeBet Player's bet
    @param _gameData Player's game data
    @param _sign Player's game data sign
    */
    function openDispute(
        bytes32   _id,
        uint256   _session,
        uint256[] _disputeBets,
        gameData  _gameData,
        bytes     _sign
    )
        public
        active(channels[_id])
    {
        Channel storage _channel = channels[_id];
        checkOpenDispute(_id, _session, _disputeBets, _gameData, _sign);

        if (_channel.endBlock.sub(block.number) < safeTime) {
            _channel.endBlock = block.number.add(safeTime);
        }

        Dispute memory _dispute = Dispute({
            disputeBets     : _disputeBets,
            disputeGameData : _gameData
        });
             
        //_channel.totalBet = _channel.totalBet.add(_disputeBet);
        disputes[_id]   = _dispute;
        _channel.status = Status.dispute;
        
        emit logChannel("open dispute", _id);
    }

    /**
    @notice Checks data for the dispute opening
    @param _id          Unique channel identifier
    @param _session     Number of the game session
    @param _disputeSeed Seed for generate random
    @param _disputeBet  Player's bet
    @param _gameData    Player's game data
    @param _sign        Player's game data sign
    */
    function checkOpenDispute (
        bytes32   _id,
        uint256   _session,
        uint256[] _disputeBets,
        gameData  _gameData,
        bytes     _sign
    )
        public
        view
        returns (bool)
    {
        Channel storage _channel = channels[_id];
        bytes32 gameDataHash     = hashGameData(_gameData);
        address _signer          = Utils.recoverSigner(gameDataHash, _sign);
        require(
            _session == _channel.session.add(1),
            'invalid channel session'
        );
        require(
            _signer == _channel.player,
            'signer is not player'
        );
        require(
            gameLogic.checkGameData(_gameData, _disputeBets),
            'invalid game data'
            );
        require(
            gameLogic.getProfit(_gameData, _disputeBets) <= _channel.bankrollerBalance,
            'invalid bet'
            );
        return true;
    }

    /**
    @notice Closing of the channel on the dispute
    @param _id Unique channel identifier
    @param _N N-component of bankroller's rsa public key 
    @param _E E-component of bankroller's rsa public key 
    @param _rsaSign sign for generate random
    */
    function resolveDispute(
        bytes32 _id,
        bytes   _N,
        bytes   _E,
        bytes   _rsaSign
    )
        public
    {
        checkResolveDispute(_id, _N, _E, _rsaSign);
        resolveGame(_id, _rsaSign);
    }

    /**
    @notice Checks data for the closing of the channel on the dispute
    @param _id Unique channel identifier
    @param _N N-component of bankroller's rsa public key
    @param _E E-component of bankroller's rsa public key
    @param _rsaSign sign for generate random
    */
    function checkResolveDispute(
        bytes32 _id,
        bytes   _N,
        bytes   _E,
        bytes   _rsaSign
    )
        public 
        view
        returns (bool)
    {
        Channel storage _channel = channels[_id];
        Dispute storage _dispute = disputes[_id];
        bytes32 _hash = keccak256(abi.encodePacked(_id, _channel.session.add(1), _dispute.disputeBets, _dispute.disputeGameData.seed));
        require(
            _channel.status == Status.dispute,
            'invalid channel status'
            );
        require(
            msg.sender == _channel.bankroller,
            'sender is not player'
            );
        require(
            _channel.endBlock < block.number,
            'invalid block number'
            );
        require(
            keccak256(abi.encodePacked(keccak256(_N), keccak256(_E))) == _channel.RSAHash,
            'invalid public components'
            );
        require(
            Utils.verify(_hash, _N, _E, _rsaSign),
            'invalid RSA signature'
            );
        return true;
    }

    /**
    @notice run last game round after dispute
    @param _id   Unique channel identifier
    @param _bet  Player bet in last round
    @param _sign Sign for creation random number
    */
    function resolveGame(bytes32 _id, bytes _sign) internal {
        int256[2] memory profits;
        Channel storage _channel = channels[_id];
        Dispute storage _dispute = disputes[_id];
        uint256[] memory randoms = generateRnd(_dispute.disputeGameData.randomRanges, _sign);
        profits = gameLogic.game(disputes[_id].disputeGameData, disputes[_id].disputeBets, randoms);
        //TODO
        emit logChannel("resolve dispute", _id);
        closeChannel(_id);
    }

    /**
    @notice Internal function for for sending funds
    @param _id Unique channel identifier
    */
    function closeChannel(bytes32 _id) internal {
        Channel storage _channel = channels[_id];
        uint256 _forReward;
        uint256 _forPlayer;
        uint256 _forBankroller;
        (_forReward, _forPlayer, _forBankroller) = rewardCalc(_channel);
        serviceReward(_channel.player, _forReward);
        token.transfer(_channel.player, _forPlayer);
        token.transfer(_channel.bankroller, _forBankroller);
        platform.payout(_channel.player, _forPlayer);
        platform.payout(_channel.bankroller, _forBankroller);
        removeChannel(_id);
    }

    /**
    @notice reward calculation
    @param _channel Channel channel struct
    */
    function rewardCalc(
        Channel storage _channel
    )
        internal
        view
        returns(uint256 _forReward, uint256 _forPlayer, uint256 _forBankroller)
    {
        _forReward                = _channel.totalBet.mul(20).div(1000);
        uint256 _bankrollerReward = _forReward.mul(config.bankrollReward).div(100);
        _forPlayer                = _channel.playerBalance;
        _forBankroller            = uint(0);

        if(_forReward > _channel.bankrollerBalance) {
            _forPlayer = _forPlayer.sub(_forReward);
        } else {
            _forBankroller = ((_channel.bankrollerBalance.add(_bankrollerReward).sub(_forReward)));
        }
    }

    /**
    @notice Remove channel struct
    @param _id Id channel struct
    */
    function removeChannel(bytes32 _id) internal {
        Channel storage _channel = channels[_id];
        _channel.status = Status.close;
        delete _channel.playerBalance;
        delete _channel.bankrollerBalance;
        if (_channel.status == Status.dispute) {
            delete disputes[_id];
        }
    }

    /**
    @notice Send rewards
    @param _player Player address
    @param _value Value for reward
    */
    function serviceReward(address _player, uint256 _value) internal {
        address _platform;
        address _referrer;
        (_platform, _referrer) = platform.getService(_player);
        if (_referrer == address(0)) {
            _referrer = _platform;
        }
        token.transfer(developer, _value.mul(config.gameDevReward).div(100));
        token.transfer(_platform, _value.mul(config.platformReward).div(100));
        token.transfer(_referrer, _value.mul(config.refererReward).div(100));
    }

}