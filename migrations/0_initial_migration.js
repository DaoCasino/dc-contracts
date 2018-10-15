var Migrations = artifacts.require("./Migrations.sol");

module.exports = async function(deployer, network) {
  if(network == 'development' || network == 'develop' || network == 'coverage') {
    await deployer.deploy(Migrations)
  }
};
