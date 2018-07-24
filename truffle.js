
const HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = ".......er";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    mainnet: {
      provider: () =>
        new HDWalletProvider(mnemonic, "https://mainnet.infura.io/<YourKey>"),

      network_id: 1, // mainnet
      gasPrice: 20000000000, // 4 Gwei

    },
    ropsten: {
      // must be a thunk, otherwise truffle commands may hang in CI
      provider: () =>
        new HDWalletProvider(mnemonic, "https://ropsten.infura.io/<Yourkey>"),

      network_id: '3',
      gas: 50000000,
      
    }
  }
};