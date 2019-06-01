# Price Oracle

**Mirror**

This repo is mirrored from the Gitlab master as a backup. Please commit to this:

https://gitlab.com/canyacoin/canyacore/price-oracle
---


## What

 - Trustless on chain token price Oracle (for any ERC20 token on the Bancor network)
 - Utilises the arbitraged service provided by Bancor
 - Simulates `BancorConversion` containing US$50k in the token liquidity and US$150k in BNT-DAI liquidity 
 - Check out the CAN -> DAI [conversion on Ropsten](https://ropsten.etherscan.io/address/0x70210b58094163735e0f8e3f5120e32f9cbc3a81#readContract) 
 - Deployable and testable on testnet via truffle migration 

## How

 - `npm install -g truffle`
 - Modify settings in `2_converter_migration.js` to your ERC20 values:

```javascript
   var myTokenName = 'CanYaCoin';
   var myTokenSymbol = 'CAN';
   var myTokenDecimals = '6';

   var myTokenPriceUsd = 0.04;

   var BNTPriceUsd = 1.6;
```

 - `npm install -g ganache-cli`
 - `ganache-cli`
 - `truffle migrate --network ganache`
 - Congrats! You deployed an oracle

### Deploying to Ropsten
 - ensure you have followed the first 2 steps above
 - Fill in your details on `environment.sh` and run the script (`./environment.sh`)
 - `npm install truffle-hdwallet-provider` 
 - `truffle migrate --network ropsten`

### Deploying a copy to mainnet
 - Either choose to use a currently deployed and maintained version of the `OracleBase` contract or add these lines to your truffle migration:
 - `await deployer.deploy(ERC20BancorPriceOracleBase, <BNTToken>.address, <DAIToken>.address, <DAIBNTConverter>.address)` <- deploy base oracle (DAI -> BNT conversion)
 - `await deployer.deploy(ERC20BancorPriceOracle, <MyERC20Token>.address, <BancorToTokenConverter>.address, <ERC20BancorPriceOracleBase>.address)` <- ERC20->DAI oracle
 - Use the address of this price oracle to interact with the contract from a custom contract

## Post migration

### Interacting with the oracle
 - Load up Remix (http://remix.ethereum.org) and create/compile a file with the code from `ERC20BancorPriceOracle.sol`
 - Choose environment `Web3 Provider` on Remix and set it to localhost:8545 (ganache-cli)
 - Grab the deployed `ERC20BancorPriceOracle` address from the migration output
 - Deploy an instance of the contract at this address
 - Get the value of your token (including decimals) by hitting `getDaiToToken(1000000000000000000)`

### Use it in your contract
 - xxx

## Testnet migration

### Debug migration info
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
