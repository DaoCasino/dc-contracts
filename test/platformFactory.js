const PlatformFactory = artifacts.require('PlatformFactory');
const ERC20 = artifacts.require('ERC20');

contract('Platform Factory', function (accounts) {

    let platform;

    beforeEach('setup contracts', async function() {
        let token = await ERC20.new();
        platform = await PlatformFactory.new(token.address);
    });

    it('Should be able to create platform', async function() {
        await platform.createPlatform();
    });

    it('Should return correct data', async function() {
        let tx = await platform.createPlatform();
        let address = tx.logs[0].args.platformInstance;
        let res = await platform.isPlatform(address);
        assert.isOk(res);
    })
});