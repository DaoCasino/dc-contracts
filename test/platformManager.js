var platformManagerContract = artifacts.require('./platform/platformManager.sol')
var tokenContract = artifacts.require('ERC20.sol');
var gameFactory = artifacts.require('GameFactory.sol');
var platfromFactory = artifacts.require('PlatformFactory.sol');
var gameMarket = artifacts.require('GameMarket.sol');

const { expectThrow } = require('./helpers/expectThrow.js');

contract('platformManager', function (accounts) {

    var platformManager
    var owner = accounts[0]
    var user  = accounts[1]
    var refer = accounts[2]
    var limit = 1000

    beforeEach('contract init', async function () {
        platformManager = await platformManagerContract.new(tokenContract.address);
    })

    describe('Platform Management', function () {

        it('reg user', async function () {
            await platformManager.regUser(user, limit, refer, false, '0x42');
        })
        
        it('get user', async function () {
            await platformManager.regUser(user, limit, refer, false, '0x42');
            const res = await platformManager.getUser(user);
            assert.equal(res[0].toNumber(), 1)
            assert.equal(res[1].toNumber(), limit)
            assert.equal(res[2], refer)
        });

        it('stop user', async function () {
            await platformManager.regUser(user, limit, refer, false, '0x42');
            await platformManager.stopUser(user);
        });

        it('activate user', async function () {
            await platformManager.regUser(user, limit, refer, false, '0x42');
            await platformManager.stopUser(user);
            await platformManager.activateUser(user);
        });

        it('set max amount user', async function () {
            await platformManager.regUser(user, limit, refer, false, '0x42');
            const newAmount = 10000;
            await platformManager.setMaxAmount(user, newAmount);
        });
        
        it('get max amount user', async function () {
            await platformManager.regUser(user, limit, refer, false, '0x42');
            const newAmount = 10000;
            await platformManager.setMaxAmount(user, newAmount);
            const res = await platformManager.getMaxAmount(user);
            assert.equal(res.toNumber(), newAmount)
        });
        
        it('should be able to reg manager', async function() {
            expectThrow(platformManager.regManager(user, {from: user}));
            await platformManager.regManager(user);
        });

        it('should be able to del manager', async function() {
            expectThrow(platformManager.delManager(user, {from: user}));
            await platformManager.delManager(user);
        });

        it('should be able to reg game', async function() {
            let token = await tokenContract.deployed();
            let pFactory = await platfromFactory.new(token.address);
            let market = await gameMarket.new(user);
            await market.addGame(token.address, "byteshash", 25);
            await market.approveByAddress(token.address, {from: user});
            let factory = await gameFactory.new(token.address, pFactory.address, market.address);
            await platformManager.regGame(factory.address, token.address, 25, 25, 25);
        });

        it('Should be able to set CPA bonus', async function() {
            await platformManager.CPAInit(0, 0, 0, 0);
            expectThrow(platformManager.CPAInit(0, 0, 0, 0, {from: user}));
            await platformManager.regUser(user, limit, owner, true, '0x42');
            await platformManager.checkCPABonus(user);
            await platformManager.getCPABonus(user);
        })

    })

})