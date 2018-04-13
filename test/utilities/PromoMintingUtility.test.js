
import EVMRevert from 'zeppelin-solidity/test/helpers/EVMRevert';
import ether from 'zeppelin-solidity/test/helpers/ether';
var PromoMintingUtility= artifacts.require('utilities/minting/PromoMintingUtility.sol');
var QuadToken = artifacts.require('mocks/QuadToken.sol');
const BigNumber = web3.BigNumber;
var gas = 6721971;
const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should();


contract("PromoMintingUtility", function([_, investor, owner]) {
    beforeEach(async function() {
        this.tokenIds = [1,123212,3452345];
        this.promoIds = [180105104810,332499758092,332499758092];
        this.land = await QuadToken.new({from: owner, gas: gas});
        this.minting = await PromoMintingUtility.new(this.land.address, {from: owner, gas: gas});
    });

    it('can add tokens', async function() {
        await this.minting.addPromoTokens(this.promoIds, this.tokenIds, {from: owner});
        const outstanding = await this.minting.outstandingPromoTokens();
        console.log(outstanding);
        outstanding.should.be.bignumber.equal(this.tokenIds.length);
    });

    it('can redeem token with valid promo id', async function() {
        await this.minting.addPromoTokens(this.promoIds, this.tokenIds, {from: owner});
        const { logs } = await this.minting.redeemPromo(this.promoIds[0], investor, {from: investor});
        const event = logs.find(e => e.event === 'PromoRedeemed');
        should.exist(event);
        event.args.purchaser.should.equal(investor);
        event.args.to.should.equal(investor);
        event.args.tokenId.should.be.bignumber.equal(this.tokenIds[0]);
    });

    it('should increase redeemedPromoTokens and decrease outstanding when redeemed', async function() {
        await this.minting.addPromoTokens(this.promoIds, this.tokenIds, {from: owner});
        await this.minting.redeemPromo(this.promoIds[0], investor, {from: investor});        
        const redeemed = await this.minting.redeemedPromoTokens();
        const outstanding = await this.minting.outstandingPromoTokens();

        redeemed.should.be.bignumber.equal(1);
        outstanding.should.be.bignumber.equal(this.tokenIds.length - 1);
    });

    it('should assign tokens to beneficiary', async function () {
        await this.minting.addPromoTokens(this.promoIds, this.tokenIds, {from: owner});
        await this.minting.redeemPromo(this.promoIds[0], investor, {from: investor});        
        const balance = await this.land.balanceOf(investor);
        balance.should.be.bignumber.equal(1);
    });


});