const chalk = require('chalk');
const complete = chalk.bold.green;

const ERC20           = artifacts.require('../core/ERC20.sol');
const PlatformFactory = artifacts.require('../platform/PlatformFactory.sol');
const GameFactory     = artifacts.require('../games/GameFactory.sol');
const SafeMath        = artifacts.require('../library/SafeMath.sol');
const Utils           = artifacts.require('../library/Utils.sol');
const PlatformManager = artifacts.require('../platform/PlatformManager.sol');
const SimpleGame      = artifacts.require('../games/SimpleGame.sol');
const GameInstance    = artifacts.require('../game/GameInstance.sol');
const GameMarket      = artifacts.require('../core/GameMarket.sol');
const Blacklist       = artifacts.require('../core/Blacklist.sol');

module.exports = async function (deployer, network, accounts) {
    console.log(complete(
        `
                        Contracts deployed!
        -------------------------------------------------------------
                            Protocol
        -------------------------------------------------------------
        Token address    : ${ERC20.address}
        Platform factory : ${PlatformFactory.address}
        Games factory    : ${GameFactory.address}
        SafeMath (Lib)   : ${SafeMath.address}
        Utils    (Lib)   : ${Utils.address}
        GameMarket       : ${GameMarket.address}
        Blacklist        : ${Blacklist.address}
        -------------------------------------------------------------
                            Instance
        -------------------------------------------------------------
        Platform manager : ${PlatformManager.address}
        Game Contract    : ${SimpleGame.address}
        Game Instance    : ${GameInstance.address}
        `))
};