var BancorToTokenConverter = artifacts.require("./BancorToTokenConverter.sol");
var BancorFormula = artifacts.require("./BancorFormula.sol");
var ContractFeatures = artifacts.require("./ContractFeatures.sol");
var ContractRegistry = artifacts.require("./ContractRegistry.sol");
var DAIBNTRelaySmartToken = artifacts.require("./DAIBNTRelaySmartToken.sol");
var DAIBNTConverter = artifacts.require("./DAIBNTConverter.sol");
var DSToken = artifacts.require("./DSToken.sol");
var MyERC20Token = artifacts.require("./MyERC20Token.sol");
var BNTSmartToken = artifacts.require("./BNTSmartToken.sol");
var MyERC20RelaySmartToken = artifacts.require("./MyERC20RelaySmartToken.sol");

var ERC20BancorPriceOracleBase = artifacts.require("./ERC20BancorPriceOracleBase.sol");
var ERC20BancorPriceOracle = artifacts.require("./ERC20BancorPriceOracle.sol");

var myTokenName = 'CanYaCoin';
var myTokenSymbol = 'CAN';
var myTokenDecimals = '6';

var myTokenPriceUsd = 0.04;

var BNTPriceUsd = 1.6;

module.exports = function (deployer) {
  deployer.then(async () => {
    /* Utils deployment */
    await deployer.deploy(ContractRegistry);
    var ContractRegistryInstance = await ContractRegistry.deployed();
    await deployer.deploy(BancorFormula);
    await ContractRegistryInstance.registerAddress("0x42616e636f72466f726d756c61000000", BancorFormula.address);
    await deployer.deploy(ContractFeatures);
    await ContractRegistryInstance.registerAddress("0x436f6e74726163744665617475726573", ContractFeatures.address);

    /* BNT -> MyERC20 Contracts */
    await deployer.deploy(BNTSmartToken, "Bancor Network Token", "BNT", "18");
    var BNTSmartTokenInstance = await BNTSmartToken.deployed();
    await deployer.deploy(MyERC20Token, myTokenName, myTokenSymbol, myTokenDecimals, '10000000000');
    var MyERC20Instance = await MyERC20Token.deployed();
    await deployer.deploy(MyERC20RelaySmartToken, myTokenSymbol + " Smart Token Relay", myTokenSymbol + "BNT", "18");
    var MyERC20RelayInstance = await MyERC20RelaySmartToken.deployed();
    await deployer.deploy(BancorToTokenConverter, MyERC20RelaySmartToken.address, ContractRegistry.address, 1000, BNTSmartToken.address, 500000);
    var BancorToTokenConverterInstance = await BancorToTokenConverter.deployed();

    /* Initialise BNT -> MyERC20 state */
    await BancorToTokenConverterInstance.addConnector(MyERC20Token.address, 500000, false);
    await BNTSmartTokenInstance.issue(BancorToTokenConverter.address, (50000 / BNTPriceUsd) * (10 ** 18));
    await MyERC20Instance.transfer(BancorToTokenConverter.address, (50000 / myTokenPriceUsd) * (10 ** myTokenDecimals));
    await MyERC20RelayInstance.transferOwnership(BancorToTokenConverter.address);
    await BancorToTokenConverterInstance.acceptTokenOwnership();

    /* DAI -> BNT Contracts */
    await deployer.deploy(DSToken, '0x44414900000000000000000000000000');
    var DSTokenInstance = await DSToken.deployed();
    await deployer.deploy(DAIBNTRelaySmartToken, "DAI Smart Token Relay", "DAIBNT", "18");
    var DAIBNTRelaySmartTokenInstance = await DAIBNTRelaySmartToken.deployed();
    await deployer.deploy(DAIBNTConverter, DAIBNTRelaySmartToken.address, ContractRegistry.address, 1000, BNTSmartToken.address, 500000);
    var DAIBNTConverterInstance = await DAIBNTConverter.deployed();

    /* Initialise DAI -> BNT state */
    await DAIBNTConverterInstance.addConnector(DSToken.address, 500000, false);
    await BNTSmartTokenInstance.issue(DAIBNTConverter.address, (150000 / BNTPriceUsd) * (10 ** 18));
    await DSTokenInstance.mint(150000 * (10 ** 18));
    await DSTokenInstance.transfer(DAIBNTConverter.address, 150000 * (10 ** 18));
    await DAIBNTRelaySmartTokenInstance.transferOwnership(DAIBNTConverter.address);
    await DAIBNTConverterInstance.acceptTokenOwnership();

    /* Our price converter contracts */
    await deployer.deploy(ERC20BancorPriceOracleBase, BNTSmartToken.address, DSToken.address, DAIBNTConverter.address);
    await deployer.deploy(ERC20BancorPriceOracle, MyERC20Token.address, BancorToTokenConverter.address, ERC20BancorPriceOracleBase.address);
  })
}