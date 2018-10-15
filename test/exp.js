var exp = artifacts.require('./exp.sol')

contract('test', function () {

    var contract

    before('', async function () {
        contract = await exp.deployed()
    })

    it('check', async function () {
        const obj = [2,3]
        let res = await contract.getObj.call(obj)
        console.log(res)
    })
})