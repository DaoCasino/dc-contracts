const web3    = require('web3')
const account = require('web3-eth-accounts/node_modules/eth-lib/lib/account.js')


const toHex = value => {
    let radix
    switch (typeof value) {
        case 'number':
            radix = 16
            break;
        case 'string':
            radix = 'hex'
            break;
    }
    let hex = value.toString(radix)
    let prefix
    hex.length % 2 === 0 ? prefix = '0x' : prefix = '0x0'
    return prefix + hex
}

const hashToOpen = channel => {
    return web3.utils.soliditySha3(
    {
        t: 'address',
        v: channel.contract
    }, {
        t: 'address',
        v: channel.users
    }, {
        t: 'uint256',
        v: channel.balances
    },  {
        t: 'uint256',
        v: channel.openingBlock
    }, {
        t: 'uint256',
        v: channel.initData
    }, {
        t: 'bytes32',
        v: channel.RSAfingerprint
    })
}

const calculateId = channel => {
    return web3.utils.soliditySha3(
    {
        t: 'address',
        v: channel.contract
    }, {
        t: 'address',
        v: channel.users
    },  {
        t: 'uint256',
        v: channel.openingBlock
    })
}

const decodeSignature = hash => {
    const VRS = account.decodeSignature(hash)
    return {
        v: VRS[0],
        r: VRS[1],
        s: VRS[2],
    }
}

module.exports = {
    toHex,
    hashToOpen,
    decodeSignature,
    calculateId
}