const { ethers } = require("ethers");
const assert = require('assert');
const Ganache = require("ganache-core");
const compiledConditionalTokens = require('./build/contracts/ConditionalTokens.json');
const compiledMakerAdapter = require('./build/contracts/MakerAdapter.json');
const compiledToyToken = require('./build/contracts/ToyToken.json');

const MAINNET_NODE_URL = "https://mainnet.infura.io/v3/b5ab0c2995454d1abe5cbdfe162af992";
const PRIV_KEY = '0xe8abaa19ef6e8b36ef0a97f308f3a230be7faa53cd8155285794cd09709c6f54';

const startChain = async () => {
  const ganache = Ganache.provider({
    fork: MAINNET_NODE_URL,
    network_id: 1,
    accounts: [
      {
        secretKey: PRIV_KEY,
        balance: ethers.utils.hexlify(ethers.utils.parseEther("1000")),
      },
    ],
  })

  const provider = new ethers.providers.Web3Provider(ganache)
  const wallet = new ethers.Wallet(PRIV_KEY, provider)

  return [wallet, provider]
}

jest.setTimeout(100000)
  beforeAll(async () => {
    [wallet, provider] = await startChain();
    let conditionalTokensFactory =  new ethers.ContractFactory(compiledConditionalTokens.abi, compiledConditionalTokens.bytecode, wallet);
    conditionalTokens = await conditionalTokensFactory.deploy();
    // The address the Contract WILL have once mined
    console.log(conditionalTokens.address);
    // The transaction that was sent to the network to deploy the Contract
    console.log(conditionalTokens.deployTransaction.hash);
    // The contract is NOT deployed yet; we must wait until it is mined
    await conditionalTokens.deployed();
  
  let makerAdapterFactory =  new ethers.ContractFactory(compiledMakerAdapter.abi, compiledMakerAdapter.bytecode, wallet);
   // Notice we pass in the address of the conditional tokens contract as the parameter to the constructor
   makerAdapter = await makerAdapterFactory.deploy(conditionalTokens.address);
   // The address the Contract WILL have once mined
   console.log(makerAdapter.address);
   // The transaction that was sent to the network to deploy the Contract
   console.log(makerAdapter.deployTransaction.hash);
   // The contract is NOT deployed yet; we must wait until it is mined
   await makerAdapter.deployed();

   let toyTokenFactory =  new ethers.ContractFactory(compiledToyToken.abi, compiledToyToken.bytecode, wallet);
   
   toyToken = await toyTokenFactory.deploy("t1", "t1");
   // The address the Contract WILL have once mined
   console.log(toyToken.address);
   // The transaction that was sent to the network to deploy the Contract
   console.log(toyToken.deployTransaction.hash);
   // The contract is NOT deployed yet; we must wait until it is mined
   await toyToken.deployed();
   cTokens = new ethers.Contract(conditionalTokens.address, compiledConditionalTokens.abi, provider);
   mkAdapter = new ethers.Contract(makerAdapter.address, compiledMakerAdapter.abi, provider);
   token = new ethers.Contract(toyToken.address, compiledToyToken.abi, provider);
});


describe("contract deployment",  () => {
  




 



  test('deploys a conditional token contract', () => {
    assert.ok(conditionalTokens.address);
    

  });
  test('deploys a maker adapter contract', () => {
    assert.ok(makerAdapter.address);
    

  });
  test('deploys a toy token contract', async () => {
    assert.ok(toyToken.address);
    const name = await token.functions.name();
    expect(name).toBe("t1")
    

  });

})
