var GameMarket = artifacts.require('./core/GameMarket.sol')
var simpleGame = artifacts.require('./games/simpleGame.sol')
const { expectThrow } = require('./helpers/expectThrow.js');

contract('GameMarket', function(accounts) {
	let marketContract, game
	let owner = accounts[0]
	let dev   = accounts[1]
	let other = accounts[2]

	beforeEach('setup contract', async function() {
		marketContract = await GameMarket.new(owner)
		game           = await simpleGame.new()
	}) 

	it('able to add new game', async function() {
		const tx = await marketContract.addGame(game.address, "hash", 100)
		console.log(`Gas used: ${tx.receipt.gasUsed}`)
	})

	it('unable to add new game with existing address', async function () {
		await marketContract.addGame(game.address, "hashstring", 100)
		expectThrow(marketContract.addGame(game.address, "hashstring", 100))
	})

	it('unable to add game with wrong address', function () {
		expectThrow(marketContract.addGame("0x0", "hashstring", 100))
	})

	it('unable to add game negative reward', function () {
		expectThrow(marketContract.addGame(game.address, "hashstring", -100))
	})

	it('unable to add game with wrong percent', async function () {
		expectThrow(marketContract.addGame(game.address, "hashstring", 101))
	})

	it('unable to add game with wrong hash', async function () {
		expectThrow(marketContract.addGame(game.address, "", 100))
	})

	it('unable to add game with non-contract address', async function() {
		expectThrow(marketContract.addGame(owner, "hash", 100))
	})

	it('able to remove game', async function () {

		await marketContract.addGame(game.address, "fref", 100, {from: dev})
		let id = await marketContract.getId(game.address)
		id = id.toNumber()
		const tx = await marketContract.removeGame(id, {from: dev})
		console.log(`Gas used: ${tx.receipt.gasUsed}`)
	})

	it('game cannot be removed by non-developer', async function () {
		await marketContract.addGame(game.address, "hahs", 100, {from: dev})
		expectThrow(marketContract.removeGame(game.address, {from: other}))
	})

	it('able to approve game', async function () {
		await marketContract.addGame(game.address, "hash", 100, {from: dev})
		const tx = await marketContract.approveByAddress(game.address)
		console.log(`Gas used: ${tx.receipt.gasUsed}`)
	})

	it('non-admin cannot approve game', async function () {
		await marketContract.addGame(game.address, "hash", 100, {from: dev})
		expectThrow(marketContract.approveByAddress(game.address, {from: other}))
	})

	it('unable to approve non-existing game', async function () {
		expectThrow(marketContract.approveByAddress(game.address))
	})

	it('able to decline game', async function () {
		await marketContract.addGame(game.address, "hash", 100, {from: dev})
		let id = await marketContract.getId(game.address)
		id = id.toNumber()
		await marketContract.decline(id)
	})

	it('unable to decline non-existing game', async function () {
		expectThrow(marketContract.decline(game.address))
	})

	it('non-admin cannot decline game', async function () {
		await marketContract.addGame(game.address, "hash", 100, {from: dev})
		expectThrow(marketContract.decline(game.address, {from: other}))
	})

	it('getters should return right value', async function () {
		await marketContract.addGame(marketContract.address, "hash", 100)
		let id  = await marketContract.getId(marketContract.address)
		id = id.toNumber()
		// let ipfs      = await marketContract.getGameIpfs(id)
		// let developer = await marketContract.getDeveloper(id)
		// let reward    = await marketContract.getReward(id)
		// let game 	  = await marketContract.getGame(id);
		// let bool 	  = await marketContract.isAccepted(id);
		// await marketContract.getRewardByAddress(marketContract.address);
		// await marketContract.getDeveloperByAddress(marketContract.address);
	})

	it('able to update game', async function () {
		await marketContract.addGame(game.address, "hash", 100);
		let id = await marketContract.getId(game.address);
		id = id.toNumber();
		await marketContract.updateGame(id, "newhash", 100);
	})

	it('unable to update game by non-developer', async function () {
		await marketContract.addGame(game.address, "hash", 100)
		expectThrow(marketContract.updateGame(game.address, "newhash", 100, {from: other}))
	})

	it('unable to update contract with wrong data', async function () {
		await marketContract.addGame(game.address, "hash", 100)
		expectThrow(marketContract.updateGame(game.address, "", 100))
		expectThrow(marketContract.updateGame(game.address, "hash", -10))
	})

	it('should be able to update game', async function() {
		await marketContract.addGame(game.address, "hash", 100);
		let id  = await marketContract.getId(game.address);
		id = id.toNumber();
		await marketContract.updateGame(id, "newhash", 10);
	});

	it('should be able to request approve', async function() {
		await marketContract.addGame(game.address, "hash", 100);
		let id  = await marketContract.getId(game.address);
		id = id.toNumber();
		await marketContract.requestApprove(id);
	});

	it('should be able to approve game by index', async function() {
		await marketContract.addGame(game.address, "hash", 100);
		let id  = await marketContract.getId(game.address);
		id = id.toNumber();
		await marketContract.requestApprove(id);
		await marketContract.approveByIndex(id);
	});
})
