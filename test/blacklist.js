const Blacklist = artifacts.require('Blacklist');
const { expectThrow } = require('./helpers/expectThrow.js');

contract('Blacklist', function(accounts) {
   let blacklist;

   beforeEach('setup contract', async function() {
       blacklist = await Blacklist.new(accounts[0]);
   });

   it('Should be able to add address to blacklist', async function() {
       await blacklist.addUser(accounts[1]);
       expectThrow(blacklist.addUser(accounts[1], {from: accounts[1]}));
   });

   it('Should be able to remove address from blacklist', async function() {
       await blacklist.addUser(accounts[1]);
       await blacklist.delUser(accounts[1]);
       expectThrow(blacklist.delUser(accounts[1], {from: accounts[1]}));
   });

   it('Should return correct data', async function() {
       await blacklist.addUser(accounts[1]);
       let res = await blacklist.checkUser(accounts[1]);
       assert.isOk(res);
   });
});
