const HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    ganache: {
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      network_id: '*'
    },
    ropsten: {
      network_id: 3,
      gas: 4500000,
      gasPrice: 45000000000, // 45 GWei
      provider: function () {
        return new HDWalletProvider(process.env.WALLET_MNEMONIC, `https://ropsten.infura.io/v3/${process.env.INFURA_ADMIN_API_KEY}`)
      }
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};