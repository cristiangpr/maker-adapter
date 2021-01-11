# maker-adapter

Enables prediction markets based on Maker DAO price oracles. 
Must be used with Gnosis Conditional Tokens contract.
Index sets for short and long outcome collections should be set to 1 and 2 respectively.
To set up a "all or nothing" binary market set variation to 0 at market preparation.
To set up a scalar market set variation to define desired range. Upper and lower bounds are defined by targetValue +- variation.
If price is higher or lower than bounds at resolution time payouts will be all or nothing. If it falls within the range payouts will be proportional.


Interact with contract on Etherscan https://etherscan.io/address/0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777
Cuurently whitelisted on ETH/USD OSM 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763. More coming soon.
