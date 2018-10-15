const GameFactory     = artifacts.require('../games/GameFactory.sol');
const ERC20           = artifacts.require('../core/ERC20.sol');
const PlatformFactory = artifacts.require('../platform/PlatformFactory.sol');
const Utils           = artifacts.require('../library/Utils.sol');
const GameMarket      = artifacts.require('../core/GameMarket.sol');
const SafeMath        = artifacts.require('../library/SafeMath.sol');


module.exports = async function (deployer, network, accounts) {
        await deployer.link(Utils, GameFactory);
        await deployer.link(SafeMath, GameFactory);
        await deployer.deploy(GameFactory, ERC20.address, PlatformFactory.address, GameMarket.address);
};