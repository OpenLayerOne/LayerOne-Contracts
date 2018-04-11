
import EVMRevert from 'zeppelin-solidity/test/helpers/EVMRevert';
import ether from 'zeppelin-solidity/test/helpers/ether';
var FixedMintingUtility= artifacts.require('utilities/minting/FixedMintingUtility.sol');
var LayerOneLand = artifacts.require('mocks/LayerOneLand.sol');
const BigNumber = web3.BigNumber;
var gas = 6721971;
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();


contract("FixedMintingUtility", function([_, investor, coreOwner]) {
    beforeEach(async function() {
        this.tokenIds = [1,123212,3452345];
        this.land = await LayerOneLand.new({from: coreOwner, gas: gas});
        this.minting = await FixedMintingUtility.new(this.land.address, {from: coreOwner, gas: gas});
        this.price = new BigNumber(await this.minting.fixedPrice());
    });

    it('should log purchase', async function() {
        const { logs } = await this.minting.fixedPricePurchase(this.tokenIds, 0x0, {from: investor, value: this.price});
        const event = logs.find(e => e.event === 'LandPurchase');
        should.exist(event);
        event.args.purchaser.should.equal(investor);
        event.args.beneficiary.should.equal(investor);
        event.args.value.should.be.bignumber.equal(this.price);
    });

    it('should increase balance of contract', async function() {
        await this.minting.fixedPricePurchase(this.tokenIds, 0x0, {from: investor, value: this.price});
        const newBalance = await web3.eth.getBalance(this.minting.address);
        newBalance.should.be.bignumber.equal(this.price);
    });

    it('should assign tokens to beneficiary', async function () {
        await this.minting.fixedPricePurchase(this.tokenIds, 0x0, {from: investor, value: this.price});
        const balance = await this.land.balanceOf(investor);
        balance.should.be.bignumber.equal(this.tokenIds.length);
    });

    it('should allow updating fixed price', async function () {
        await this.minting.updateFixedPrice(ether(1), {from: coreOwner});
        await this.minting.fixedPricePurchase(this.tokenIds, 0x0, {from: investor, value: this.price}).should.not.be.fulfilled;        await this.minting.fixedPricePurchase(this.tokenIds, 0x0, {from: investor, value: this.price}).should.not.be.fulfilled;
        await this.minting.fixedPricePurchase(this.tokenIds, 0x0, {from: investor, value: ether(1)}).should.be.fulfilled;
    });
});