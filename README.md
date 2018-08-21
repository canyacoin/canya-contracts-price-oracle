## What

 - Bancor currency conversion


## How

 - `npm install -g truffle`
 - Modify settings in `2_converter_migration.js` to your ERC20 values
 - `npm install -g ganache-cli`
 - `ganache-cli`
 - `truffle migrate --network ganache`


## Post migration

### Check your token ratio to BNT
 - Load up Remix (http://remix.ethereum.org) and create/compile a file with the `BancorConverter.sol`
 - Choose environment `Web3 Provider` on Remix and set it to localhost:8545 (ganache-cli)

 - BNT -> ERC20
     - Grab the deployed `BancorToTokenConverter` address from the migration output, head to Remix and connect to an instance of `BancorConverter` at that address 
     - Interact with the `getReturn` function with the following parameters
         - `_fromToken` (BNT token address) -> execute `connectorTokens(0)` on the deployed contract
         - `_toToken` (MyERC20 token address) -> execute `connectorTokens(1)` on the deployed contract
         - `_amount` -> 1000000000000000000 (1 * 10**[BNT Decimals])
     - Return value should be (1/`myTokenRatioToBNT`) * (10**`myTokenDecimals`)
 - DAI -> BNT
     - Grab the deployed `DAIBNTConverter` address from the migration output, head to Remix and connect to an instance of `BancorConverter` at that address 
     - Interact with the `getReturn` function with the following parameters
         - `_fromToken` (DAI token address) -> execute `connectorTokens(1)` on the deployed contract
         - `_toToken` (BNT token address) -> execute `connectorTokens(0)` on the deployed contract
         - `_amount` -> 1000000000000000000 (1 * 10**[DAI Decimals])
     - Return value should be (1/`currentBNTDAIRatio`) * (10**18)
 - To do a DAI -> ERC20 calculation, grab the output from DAI -> BNT and use it as the amount in BNT -> ERC20
 15.624599

## Note
 - Had to create multiple ERC20 contracts with different names in order to play nice with the truffle migration script