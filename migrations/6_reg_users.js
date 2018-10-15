const chalk = require('chalk');
const reg   = chalk.bold.yellow;

const PlatformManager = artifacts.require('../platform/PlatformManager.sol')
const ERC20           = artifacts.require('../core/ERC20.sol')


module.exports = async function (deployer, network, accounts) {
        var Token    = await ERC20.deployed()
        var Platform = await PlatformManager.deployed()

        var maxDeposit = 10000*10**18

        accounts.forEach(async (account, index) => {
            await Platform.regUser(account, maxDeposit, accounts[0], false, '0x0')
            await Token.faucet({from: account})
            let BETbalance = await Token.balanceOf(account)
            console.log(reg(`
        Account #${index}
        -------------------------------------------------------
        account     : ${account}
        affilate    : ${accounts[0]}
        BET balance : ${BETbalance / 10**18} BET
        maxDeposit  : ${maxDeposit / 10**18} BET
        -------------------------------------------------------
        `))
    })
};
