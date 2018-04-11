require('babel-register')({
  ignore: /node_modules\/(?!zeppelin-solidity)/
});
require('babel-polyfill');
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      gas: 6721975,
      gasPrice: 4200000,
      network_id: "*" // Match any network id
    },
    kovan: {
      network_id: '*',
      host:'localhost',
      port:8545,
      gas: 6986331,
      // gasPrice: 20000000000, // .1344 - .139 eth per contract
      gasPrice: 200000000, // .001344 - .139 eth per contract
      from: "0x8EAd0450cE2b7B21F313a3232f83121c768FcA71"
    },
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
