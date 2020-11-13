const MakerAdapter = artifacts.require("MakerAdapter");

module.exports = function (deployer) {
  deployer.deploy(MakerAdapter, '0xf09F9DD23147E5B4139545Bc9ECf282922ec0a1D');
};
