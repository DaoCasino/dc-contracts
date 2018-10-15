const SimpleGame = artifacts.require('../games/SimpleGame.sol')
const SafeMath = artifacts.require('../library/SafeMath.sol')

module.exports = async function (deployer, network, accounts) {
    await deployer.link(SafeMath, SimpleGame)
    await deployer.deploy(SimpleGame)
};