const ERC20           = artifacts.require('../core/ERC20.sol');
const PlatformFactory = artifacts.require('../platform/PlatformFactory.sol');
const Utils           = artifacts.require('../lib/Utils.sol');
const SafeMath        = artifacts.require('../lib/SafeMath.sol');
const GameMarket      = artifacts.require('../core/GameMarket.sol');
const Blacklist       = artifacts.require('../core/Blacklist.sol');

module.exports = async function (deployer, network, accounts) {
    if (network !== 'ropsten' || network !== 'mainnet') {
        // Deploy libraries
        await deployer.deploy(SafeMath);
        await deployer.deploy(Utils);
        
        deployer.link(SafeMath, ERC20);
        
        await deployer.deploy(ERC20);
        await deployer.deploy(PlatformFactory, ERC20.address);
        await deployer.deploy(GameMarket, accounts[0]);
        await deployer.deploy(Blacklist, accounts[0]);
    }
};