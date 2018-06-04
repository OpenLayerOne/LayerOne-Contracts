
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

contract('QuadToken_Metadata', ([_, owner0, owner1, recipient, protocolOwner, lrgOwner]) => {
    const qk1 = new BinaryQuadkey.fromQuadkey("0231010202322300");
    const qk2 = new BinaryQuadkey.fromQuadkey("0331010202322300");
    const tile1 = qk1.toString()
    const tile2 = qk2.toString()

    beforeEach(async function _() {
        this.token = await QuadToken.new({ from: owner0, gasPrice: 0 })
        await this.token.setMintingOn(true, {from: owner0, gasPrice: 0})
    })
    it('should be able to update many land metadata', async function _() {
      // should have metadata assigned when assigning new parcel
      await this.token.publicMinting(owner0, [tile1, tile2])
      const l2b4 = await this.token.getTokenMetadata(1, tile2)
      l2b4.should.be.equal('')

      // should be able to update using helper function
      await this.token.updateTokenMetadata(1, tile2, 'wat', { from: owner0, gasPrice: 0}).should.be.fulfilled
      const l2b42 = await this.token.getTokenMetadata(1, tile2)
      l2b42.should.be.equal('wat')

      // should be able to update many metadata at once
      const result = await this.token.updateManyTokenMetadata(1, [tile1, tile2], 'blah', { from: owner0, gasPrice: 0 }).should.be.fulfilled
      const l1 = await this.token.getTokenMetadata(1,tile1)
      const l2 = await this.token.getTokenMetadata(1,tile2)
      l1.should.be.equal('blah')
      l2.should.be.equal('blah')
    })

    describe('MetaData protocols', () => {
        const protocolId = 1
      beforeEach(async function _() {
        this.lrgToken = await LRGToken.new({from:lrgOwner});
        await this.token.createMetadataProtocol(protocolId, 2000, 1000, lrgOwner, protocolOwner, this.lrgToken.address)
      })
      it('should be able to view protocol data', async function _() {
        const data = await this.token.metadataProtocols(protocolId)
        console.log("protocol data", data)
      })
    })
  })