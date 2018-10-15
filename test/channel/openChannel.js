const account               = require('web3-eth-accounts/node_modules/eth-lib/lib/account.js')
const {expectThrow}         = require('../helpers/expectThrow.js')
const Dc                    = require('../helpers/Dc.js')
const NodeRSA               = require('node-rsa');

const SimpleGame  = artifacts.require("GameInstance")
const erc20       = artifacts.require("ERC20")
const platformCon = artifacts.require("PlatformManager")

//for using web3 v1.0-beta
const privateKeys = [
    '0xc87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3',
    '0xae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f',
    '0x0dbbe8e4ae425a6d2687f1a7e3ba17bc98c673636790f1b8ad91193c05875ef1',
    '0xc88b703fb08cbea894b6aeff5a544fb92e78a18e19814cd85da83b71f772aa6c'
]

contract('Opening channel', function (accounts) {
    
    var playerRSA;
    var bankrollerRSA;

    var owner      = accounts[0]
    var player     = accounts[1]
    var bankroller = accounts[2]
    var hacker     = accounts[3]

    playerPrivateKey     = privateKeys[1]
    bankrollerPrivateKey = privateKeys[2]

    const BET = 10 ** 18

    var platform
    var token

    before('setup contract', async function () {
        token    = await erc20.deployed()
        DiceGame = await SimpleGame.deployed()
        platform = await platformCon.deployed()
    })

    /*
    Init environment:
    - approve
    - generate RSA keys
    */
    describe('init', function () {

        describe('faucet', function () {
            
            it('get faucet', async function () {
                await token.faucet({from: player})
                await token.faucet({from: bankroller})
            })

        })

        describe('approve', function () {

            // it('check', async function () {
            //     let res1 = await platform.token.call()
            //     let res2 = await DiceGame.token.call()
            //     console.log(res1, res2)
            // })

            it('Approve from player', async function () {
                await token.approve(platform.address, 10000, {
                    from: player
                })
            })

            it('check allowed from player', async function () {
                let allowance = await token.allowance.call(player, platform.address) 
                assert.equal(allowance, 10000, 'no approve from player')
            })

            it('Approve from bankroller', async function () {
                await token.approve(platform.address, 10000, {
                    from: bankroller
                })
            })

            it('check allowed from bankroller', async function () {
                let allowance = await token.allowance.call(bankroller, platform.address)
                assert.equal(allowance, 10000, 'no approve from player')
            })

        })

    });

    describe('openChannel', function () {
        var _E, _N
        var v = []
        var r = []
        var s = []
        var channel = {
            users: [],
            balances: []
        }

        var bankrollerRSA, playerRSA

        describe('generate RSA keys', function () {
            
            before('init RSA' , function () {
                bankrollerRSA = new NodeRSA();
                playerRSA     = new NodeRSA();
            })

            it('generate private key for bankroller', function () {
                bankrollerRSA.generateKeyPair()
            })

            it('generate bankroller public key for player', function () {
                const dealerPublic = bankrollerRSA.exportKey('components-public')
                playerRSA.importKey({n: dealerPublic.n, e: dealerPublic.e,}, 'components-public');
            })

        })

        describe('init opening data',  function () {

            it('init', async function () {
                channel.contract     = DiceGame.address
                channel.users[0]     = player
                channel.users[1]     = bankroller
                channel.balances[0]  = 100
                channel.balances[1]  = 200
                channel.openingBlock = await web3.eth.getBlockNumber()
                channel.initData     = '0x42'
                channel.id = Dc.calculateId(channel)
                
                const dealerPublic = bankrollerRSA.exportKey('components-public')
                _N = Dc.toHex(dealerPublic.n)
                _E = Dc.toHex(dealerPublic.e)
                
                channel.RSAfingerprint = web3.utils.soliditySha3({t:'bytes', v:_N}, {t:'bytes', v:_E})
            })

            it('player sign data', function () {
                let hash   = Dc.hashToOpen(channel)
                let sign   = account.sign(hash, playerPrivateKey)
                let signer = account.recover(hash, sign)
                let playerVRS = Dc.decodeSignature(sign)
                v[0] = playerVRS.v
                r[0] = playerVRS.r
                s[0] = playerVRS.s
                assert.equal(player, signer, 'player is not a signer')
            })

            it('bankroller sign data', function () {
                let hash = Dc.hashToOpen(channel)
                let sign = account.sign(hash, bankrollerPrivateKey)
                let signer = account.recover(hash, sign)
                let bankrollerVRS = Dc.decodeSignature(sign)
                v[1] = bankrollerVRS.v
                r[1] = bankrollerVRS.r
                s[1] = bankrollerVRS.s
                assert.equal(bankroller, signer, 'bankroller is not a signer')
            })

            it('check open channel', async function () {
                let result = await DiceGame.checkOpenChannel.call(
                    channel.users,
                    channel.balances,
                    channel.openingBlock,
                    channel.initData,
                    channel.RSAfingerprint,
                    v, r, s)
                    assert.isOk(result)
            })
            
            it('open channel', async function () {
                let tx = await DiceGame.openChannel(
                    channel.users,
                    channel.balances,
                    channel.openingBlock,
                    channel.initData,
                    channel.RSAfingerprint,
                    v, r, s)
                    console.log('id', id)
            })
        })

    })
}) 