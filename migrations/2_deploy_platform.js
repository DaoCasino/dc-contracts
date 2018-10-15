const PlatformFactory = artifacts.require('../platform/PlatformFactory.sol');
const PlatformManager = artifacts.require('../platform/PlatformManager.sol');
const ERC20           = artifacts.require('../core/ERC20.sol');

module.exports = async function (deployer, network, accounts) {
    if (network !== 'ropsten' || network !== 'mainnet') {
            let factory = await PlatformFactory.deployed();
            let tx      = await factory.createPlatform();
            PlatformManager.address = tx.logs[0].args.platformInstance;
    }
};