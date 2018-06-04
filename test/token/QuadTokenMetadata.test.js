
import assertRevert from 'openzeppelin-solidity/test/helpers/assertRevert'
import EVMRevert from 'openzeppelin-solidity/test/helpers/EVMRevert'
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock'
import Long from 'long'
import generateQuadKeys from './generateQuadKeys'
const QuadToken = artifacts.require('QuadToken.sol')
const LRGToken = artifacts.require('LRGToken.sol')
const BigNumber = web3.BigNumber
const BinaryQuadkey = require('binaryquadkey')
const Quadkey = artifacts.require('libraries/QuadkeyLib.sol');

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('QuadToken_Metadata', ([_, landContractOwner, owner1, metadataOwner, protocolOwner, lrgOwner]) => {
    const qk1 = new BinaryQuadkey.fromQuadkey("0231010202322300");
    const qk2 = new BinaryQuadkey.fromQuadkey("0331010202322300");
    const tile1 = qk1.toString()
    const tile2 = qk2.toString()

    beforeEach(async function _() {
        this.token = await QuadToken.new({ from: landContractOwner, gasPrice: 0 })
        await this.token.setMintingOn(true, {from: landContractOwner, gasPrice: 0})
    })
    it('should be able to update many land metadata', async function _() {
      // should have metadata assigned when assigning new parcel
      await this.token.mint(landContractOwner, [tile1, tile2], { from: landContractOwner})
      const l2b4 = await this.token.getTokenMetadata(1, tile2)
      l2b4.should.be.equal('')

      // should be able to update using helper function
      await this.token.updateTokenMetadata(1, tile2, 'wat', { from: landContractOwner, gasPrice: 0}).should.be.fulfilled
      const l2b42 = await this.token.getTokenMetadata(1, tile2)
      l2b42.should.be.equal('wat')

      // should be able to update many metadata at once
      const result = await this.token.updateManyTokenMetadata(1, [tile1, tile2], 'blah', { from: landContractOwner, gasPrice: 0 }).should.be.fulfilled
      const l1 = await this.token.getTokenMetadata(1,tile1)
      const l2 = await this.token.getTokenMetadata(1,tile2)
      l1.should.be.equal('blah')
      l2.should.be.equal('blah')
    })

    describe('MetaData protocols', () => {
        const protocolId = 1
      beforeEach(async function _() {
        this.lrgToken = await LRGToken.new({from:lrgOwner});
        this.createReward = 2000
        this.updateReward = 1000
        await this.token.createMetadataProtocol(protocolId, 
            this.createReward, 
            this.updateReward,
            lrgOwner, 
            protocolOwner,
            this.lrgToken.address)
        this.lrgToken.approve(this.token.address, 4000, {from: lrgOwner})
      })
      it('should be able to view protocol data', async function _() {
        const [createReward, updateReward, wallet, owner, erc20address] = await this.token.metadataProtocols(protocolId)
        createReward.should.be.bignumber.equal(this.createReward)
        updateReward.should.be.bignumber.equal(this.updateReward)
        wallet.should.be.equal(lrgOwner)
        owner.should.be.equal(protocolOwner)
        erc20address.should.be.equal(this.lrgToken.address)
      })
      it('should block creating duplicate protocol', async function _() {
        await this.token.createMetadataProtocol(protocolId, 
            this.createReward, 
            this.updateReward,
            landContractOwner, 
            protocolOwner,
            this.lrgToken.address).should.be.rejectedWith(EVMRevert)
      })
      it('owner should be able to update the reward', async function _() {
        const lrg2 = await LRGToken.new({from:lrgOwner});

        await this.token.updateReward(protocolId, 
            3000, 
            2000,
            landContractOwner, 
            owner1,
            lrg2.address, {from: protocolOwner}).should.be.fulfilled

        const [createReward, updateReward, wallet, owner, erc20address] = await this.token.metadataProtocols(protocolId)
        createReward.should.be.bignumber.equal(3000)
        updateReward.should.be.bignumber.equal(2000)
        wallet.should.be.equal(landContractOwner)
        owner.should.be.equal(owner1)
        erc20address.should.be.equal(lrg2.address)
      })
      it('should reward metadata creator with erc20 token', async function () {
        await this.token.mint(owner1, [tile1, tile2], { from: landContractOwner}).should.be.fulfilled
        const { logs } = await this.token.updateTokenMetadata(protocolId, tile1, "HELLO", {from: owner1}).should.be.fulfilled
        const event = logs.find(e => e.event === 'MetadataUpdated')
        event.args.protocol.should.be.bignumber.equal(protocolId)
        event.args.tokenId.should.be.bignumber.equal(tile1)
        event.args.owner.should.equal(owner1)
        event.args.metadata.should.equal("HELLO")
        let balance = await this.lrgToken.balanceOf(owner1)
        balance.should.be.bignumber.equal(this.createReward)
        await this.token.updateTokenMetadata(protocolId, tile1, "GOODBYE", {from: owner1}).should.be.fulfilled
        let balance1 = await this.lrgToken.balanceOf(owner1)
        balance1.should.be.bignumber.equal(this.createReward + this.updateReward)
        const updatedMsg = await this.token.getTokenMetadata(protocolId, tile1)
        updatedMsg.should.be.equal("GOODBYE")
      })
    })
  })