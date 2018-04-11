import EVMRevert from 'zeppelin-solidity/test/helpers/EVMRevert';
import ether from 'zeppelin-solidity/test/helpers/ether';
var PayableUtility = artifacts.require('mocks/PayableUtility.sol')
var LayerOneLand = artifacts.require('mocks/LayerOneLand.sol');
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
        this.land = await LayerOneLand.new({from: contractOwner, gas: gas});
        this.sellLand = await SellLand.new(this.land.address, {gas: gas, from: utilityOwner});
    });

    it('should be able to place land for sale', function() {
        
    });
});