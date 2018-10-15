pragma solidity ^0.4.24;

/**
* @title Game market similar to Play Market
* @dev Contract allows to add and remove game proposals, accept and decline game proposals
*/
contract GameMarket {

	/** @dev Emits when new game proposal was added */
	event GameAdded(uint indexed gameID);

	/** @dev Emits when game proposal was approved by owner */
	event GameApproved(uint indexed gameID);

	/** @dev Emits when game proposal was declined by owner */
	event GameDeclined(uint indexed gameID);

	/** @dev Emits when game proposal was deleted by developer */
	event GameDeleted(uint indexed gameID);

	/** @dev Emits when new approve request inited by developer */
	event Request(uint indexed gameID);

	/** @dev Emits when game metadata was updated by developer */
	event GameUpdated(uint indexed gameID, string hash, uint percent);


	enum Status {empty, inited, requested, approved}

	/** @dev Struct which contains game metadata */
	struct Game {
		address developer;
		address gameContract;
		string ipfsHash;
		Status status;
		uint percent;
	}

	/** @dev Mapping where game metadata is stored */
	mapping(address => Game) games;

	/** @dev Mapping where indexes are stored */
	mapping(uint256 => address) indexes;

	/** @dev Mapping where stored accepted indexes */
	mapping(uint256 => address) accepts;

	/** @dev Contains id of contract by its address */
	mapping(address => uint) addressToId;

	/** @dev Amount of games */
	uint256 public indexAmount;

	/** @dev Owner of contract */
	address public owner;

	modifier onlyOwner() {
		require(msg.sender == owner, 'sender is not owner!');
		_;
	}

	/** @dev Used for initialization in proxy */
	constructor(address _owner) public {
		owner = _owner;
	}

	/** @dev Access modifier for Developer-functionality only */
	modifier onlyDeveloper(uint id) {
		require(games[indexes[id]].developer == msg.sender, 'msg.sender is not developer');
		_;
	}

	/**
    * @dev Adds game proposal
    * @param gameContract Address of contract
    * @param ipfsHash Hash of game source stored at IPFS
    * @param percent Percent of income which will developer receive
    */
	function addGame(address gameContract, string ipfsHash, uint percent) public returns (uint index) {

		require(percent >= 0 && percent <= 100, 'invalid percent');
		require(bytes(ipfsHash).length != 0,'invalid IPFS-hash');
		require(isContract(gameContract), 'address is not contract');
		require(games[gameContract].status == Status.empty, 'invalid status');

		indexAmount++;
		
		Game memory game = Game(msg.sender, gameContract, ipfsHash, Status.inited, percent);
		
		indexes[indexAmount] = gameContract;
		games[gameContract]  = game;
		
		addressToId[gameContract] = indexAmount;

		emit GameAdded(indexAmount);

		return indexAmount;
	}

	/**
    * @dev Updates game metadata. Can be called only by developer and only before it will be accepted
    * @param id ID of contract
    * @param ipfsHash Hash of game source stored at IPFS
    * @param percent Percent of income which will developer receive
    */
	function updateGame(uint id, string ipfsHash, uint percent) public onlyDeveloper(id) {
		require(bytes(ipfsHash).length != 0, 'invalid IPFS hash');
		require(games[indexes[id]].status == Status.inited, 'invalid status');
		require(percent >= 0 && percent <= 100, 'invalid percent');

		games[indexes[id]].ipfsHash = ipfsHash;
		games[indexes[id]].percent  = percent;

		emit GameUpdated(id, ipfsHash, percent);
	}

	/**
    * @dev Removes game proposal. Can be called only by developer
    * @param id ID of contract
    */
	function removeGame(uint id) onlyDeveloper(id) public {
		require(games[indexes[id]].status == Status.inited, 'invalid status');
		delete games[indexes[id]];
		delete indexes[id];
		emit GameDeleted(id);
	}

	function requestApprove(uint id) onlyDeveloper(id) external {
		require(games[indexes[id]].status == Status.inited, 'invalid status');
		games[indexes[id]].status = Status.requested;
		emit Request(id);
	}

	/**
    * @dev Approves game proposal. Can be called only by owner
    * @param id ID of contract
    */
	function approveByIndex(uint id) onlyOwner public {
		require(games[indexes[id]].developer != address(0), 'invalid developer address!');
		games[indexes[id]].status = Status.approved;
		accepts[id] = indexes[id];
		emit GameApproved(id);
	}

	/**
    * @dev Approves game proposal. Can be called only by owner
    * @param game ID of contract
    */
	function approveByAddress(address game) onlyOwner public {
		uint id = addressToId[game];
		require(games[indexes[id]].developer != address(0), 'invalid status');
		games[indexes[id]].status = Status.approved;
		accepts[id] = indexes[id];
		emit GameApproved(id);
	}

	/**
    * @dev Declines game proposal. Can be called only by owner
    * @param id ID of contract
    */
	function decline(uint id) onlyOwner public {
		require(games[indexes[id]].developer != address(0), 'invalid status');
		games[indexes[id]].status = Status.empty;
		emit GameDeclined(id);
	}

	/**
    * @dev Returns full struct of game (hash, developer, status)
    * @param id ID of contract
    * @return Full struct of game metadata
    */
	function getGame(uint id) external view returns (address, address, string, Status) {
		Game storage game = games[indexes[id]];
		return (game.developer, game.gameContract, game.ipfsHash, game.status);
	}

	/**
    * @dev Returns IPFS hash with sources of the game
    * @param id ID of contract
    * @return IPFS hash
    */
	function getGameIpfs(uint id) external view returns (string) {
		return games[indexes[id]].ipfsHash;
	}

	/**
    * @dev Returns is contract accepted by owner
    * @param id ID of contract
    * @return Is contract accepted by owner
    */
	function isAccepted(uint id) external view returns (Status) {
		return games[indexes[id]].status;
	}

	/**
    * @dev Returns is contract accepted by owner
    * @param gameAddress ID of contract
    * @return Is contract accepted by owner
    */
	function isAcceptedByAddress(address gameAddress) external view returns (Status) {
		uint id = addressToId[gameAddress];
		return games[indexes[id]].status;
	}


	/**
    * @dev Returns developer of contract
    * @param id ID of contract
    * @return Developer of contract
    */
	function getDeveloper(uint id) external view returns (address) {
		return games[indexes[id]].developer;
	}

	/**
    * @dev Returns developer of contract
    * @param game ID of contract
    * @return Developer of contract
    */
	function getDeveloper(address game) external view returns (address) {
		return games[game].developer;
	}

	/**
    * @dev Returns reward percentage
    * @param id ID of contract
    * @return Reward for developer
    */
	function getReward(uint id) external view returns (uint) {
		return games[indexes[id]].percent;
	}

	/**
    * @dev Returns reward percentage
    * @param game ID of contract
    * @return Reward for developer
    */
	function getReward(address game) external view returns (uint) {
		return games[game].percent;
	}

	/**
    * @dev Checks if address is contract address
    * @param gameContract Address to check
    * @return Is address a contract
    */
	function isContract(address gameContract) internal view returns (bool) {
		uint codeLength = 0;
		assembly {
			codeLength := extcodesize(gameContract)
		}

		if (codeLength == 0) {
			return false;
		} else {
			return true;
		}
	}

	function getId(address gameAddress) public view returns(uint id) {
		return addressToId[gameAddress];
	}
}