const PlatformManager = artifacts.require('../platform/PlatformManager.sol');
const GameInstance    = artifacts.require('../game/GameInstance.sol');
const GameFactory     = artifacts.require('../platform/GameFactory.sol');
const SimpleGame      = artifacts.require('../games/SimpleGame.sol');
const GameMarket      = artifacts.require('../core/GameMarket.sol');


module.exports = async function (deployer, network, accounts) {
    const market = await GameMarket.deployed();
    await market.addGame(SimpleGame.address, 'none', 25);
    await market.approveByAddress(SimpleGame.address);

    let platform = await PlatformManager.deployed();
    let tx       = await platform.regGame(GameFactory.address, SimpleGame.address, 25, 25, 25);
    GameInstance.address = tx.logs[0].args.gameContract
};