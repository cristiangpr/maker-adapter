const { ethers } = require("ethers");
require('dotenv').config();
const assert = require('assert');
const Ganache = require("ganache-core");
const truffleAssert = require('truffle-assertions');
const compiledConditionalTokens = require('./build/contracts/ConditionalTokens.json');
const compiledMakerAdapter = require('./build/contracts/MakerAdapter.json');
const compiledToyToken = require('./build/contracts/ToyToken.json');
const questionId = "0x0000000000000000000000000000000000000000000000000000000000000001";
const parentCollectionId = "0x0000000000000000000000000000000000000000000000000000000000000000";
const priceFeed = "0x729D19f657BD0614b4985Cf1D82531c67569197B"
const MAINNET_NODE_URL = process.env.MAINNET_NODE_URL;
const PRIV_KEY = process.env.PRIV_KEY;

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

  return wallet
}

jest.setTimeout(100000)
  beforeAll(async () => {
    wallet = await startChain();
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
   // instatiate contracts
   cTokens = new ethers.Contract(conditionalTokens.address, compiledConditionalTokens.abi, wallet);
   mkAdapter = new ethers.Contract(makerAdapter.address, compiledMakerAdapter.abi, wallet);
   token = new ethers.Contract(toyToken.address, compiledToyToken.abi, wallet);
   
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

describe("Maker Dao adapter",  () => {
  beforeAll(async () => {
    conditionId = await cTokens.getConditionId(mkAdapter.address, questionId, 2 )
    await cTokens.prepareCondition(mkAdapter.address, questionId, 2 );
    low =  await cTokens.getCollectionId(parentCollectionId, conditionId, 1);
    high =  await cTokens.getCollectionId(parentCollectionId, conditionId, 2);
    t1Low = await cTokens.getPositionId(toyToken.address, low);
    t1High = await cTokens.getPositionId(toyToken.address, high);
    await token.mint(wallet.address, 1000);
    await token.approve(conditionalTokens.address, 1000);
    await cTokens.splitPosition(
      toyToken.address,
      parentCollectionId,
      conditionId,
      [1,2],
      1000
      );
     
  });
  test('splits from collateral', async () => {
    
     const balance = await token.balanceOf(wallet.address);
    // balance of 0 since collateral has been sent to conditional tokens contract
     expect(balance).toEqual({"_hex": "0x00"});
     });
 
     test('reverts on invalid resolution time', async () => {
      await truffleAssert.reverts(
         mkAdapter.resolveMarket(questionId,
          priceFeed,
          //target price
        "383100791207000000000",
        // start of valid time window
        "4129050814"), "Please submit a resolution during the correct time interval"
      )
    });
 
  test('resolves market', async () => {
    await mkAdapter.resolveMarket(questionId,
      priceFeed,
      //target price
    "383100791207000000000",
    // start of valid time window
    "1604364260");
     await cTokens.redeemPositions(
      toyToken.address,
      parentCollectionId,
      conditionId,
      [1,2]
     )
     const balance = await token.balanceOf(wallet.address);
    // balance of 1000 since market has resolved and positions redeemed
     expect(balance).toEqual({"_hex": "0x03e8"});
     });
     


})
