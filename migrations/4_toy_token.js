const ToyToken = artifacts.require("ToyToken");

module.exports = function (deployer) {
  deployer.deploy(ToyToken, 'ToyToken', "TT");
};
