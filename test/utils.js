var Promise = require("bluebird");
var _ = require("lodash");
const BigNumber = web3.BigNumber;

module.exports = {
    assertEvent: function(contract, filter) {
        return new Promise((resolve, reject) => {
            var event = contract[filter.event]();
            event.watch();
            event.get((error, logs) => {
                var log = _.filter(logs, filter);
                if (!_.isEmpty(log)) {
                    resolve(log);
                } else {
                    throw Error("Failed to find filtered event for " + filter.event);
                }
            });
            event.stopWatching();
        });
    },
    printbig: function(bignum) {
        console.log(BigNumber(bignum).toNumber());
    },
    numc: function(bignum) {
        console.log(BigNumber(bignum).toNumber());
        return BigNumber(bignum).toNumber()
    },    
    nums: function(bignum) {
        return BigNumber(bignum).toString()
    },   
    numsc: function(bignum) {
        console.log(BigNumber(bignum).toString());
        return BigNumber(bignum).toString()
    },
    num: function(bignum) {
        return BigNumber(bignum).toNumber()
    },
    sleep: function(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}