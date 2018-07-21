
const HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "...";

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    }, 
    ropsten: {
      // must be a thunk, otherwise truffle commands may hang in CI
      provider: () => 
        new HDWalletProvider(mnemonic, "https://ropsten.infura.io/<Yourkey>"),
	  
      network_id: '3',
	  gas: 4500000,
    }
  }
};