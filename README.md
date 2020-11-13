# maker-adapter

Enables prediction markets based on Maker DAO price oracles. 
Must be used with Gnosis Conditional Tokens contract.
Index sets for short and long outcome collections should be set to 1 and 2 respectively.
To set up a "all or nothing" binary market set variation to 0 at market preparation.
To set up a scalar market set variation to define desired range. Upper and lower bounds are defined by targetValue +- variation.
If price is higher or lower than bounds at resolution time payouts will be all or nothing. If it falls within the range payouts will be proportional.

## Setup

After cloning and running `npm install`, you'll need a Mainnet node and a private key (any will do).

You can get one from Infura or a pseudo-archive node from https://moonnet.now.sh/

Run the tests with `npm test`.