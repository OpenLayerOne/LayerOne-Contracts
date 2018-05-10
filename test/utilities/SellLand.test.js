import EVMRevert from 'openzeppelin-solidity/test/helpers/EVMRevert';
import ether from 'openzeppelin-solidity/test/helpers/ether';
var PayableUtility = artifacts.require('mocks/PayableUtility.sol')
var QuadToken = artifacts.require('mocks/QuadToken.sol');
const BigNumber = web3.BigNumber;
var gas = 6721971;
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();

var SellLand = artifacts.require('utilities/SellLandUtlity.sol');

contract('SellLandUtlity', function ([_, contractOwner ]) {
    beforeEach(async function() {
        this.tokenIds = [1,123212,3452345];
        this.land = await QuadToken.new({from: contractOwner, gas: gas});
        this.sellLand = await SellLand.new(this.land.address, {gas: gas, from: utilityOwner});
    });

    it('should be able to place land for sale', function() {
        
    });
});