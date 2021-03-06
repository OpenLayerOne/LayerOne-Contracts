import assertRevert from 'openzeppelin-solidity/test/helpers/assertRevert'
import EVMRevert from 'openzeppelin-solidity/test/helpers/EVMRevert'
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock'
import Long from 'long'
import generateQuadKeys from './generateQuadKeys'
const QuadToken = artifacts.require('QuadToken.sol')
const BigNumber = web3.BigNumber
const BinaryQuadkey = require('binaryquadkey')
const Quadkey = artifacts.require('libraries/QuadkeyLib.sol');

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('QuadToken', ([_, owner0, owner1, owner2, recipient, protocolOwner, lrgOwner]) => {
  const qk1 = new BinaryQuadkey.fromQuadkey("0231010202322300");
  const qk2 = new BinaryQuadkey.fromQuadkey("0331010202322300");
  const tile1 = qk1.toString()
  const tile2 = qk2.toString()
  const tile3 = (new BinaryQuadkey.fromQuadkey("0331010202322320")).toString()
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  before(async function _() {
    // Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
    await advanceBlock()
  })

  beforeEach(async function _() {
    this.token = await QuadToken.new({ from: owner0, gasPrice: 0 })
    await this.token.setMintingOn(true, {from: owner0, gasPrice: 0})
  })

  describe('Minting', () => {
    
    beforeEach(async function _() {
      await this.token.mint(owner0, [tile1], { from: owner0})
      this.qk = await Quadkey.new();
    })

    it('should return the correct totalSupply after minting a tile', async function _() {
      const totalSupply = await this.token.totalSupply()
      assert.equal(totalSupply.toDigits(), 1)
    })

    it('should return correct balances after transfer', async function _() {
      await this.token.mint(owner1, [tile2], { from: owner0})
      const token = await this.token.tokenOfOwnerByIndex(owner0, 0)
      await this.token.transferFromMany(owner0, owner1, [tile1], { from: owner0 })
      const firstAccountBalance = await this.token.balanceOf(owner0)
      assert.equal(firstAccountBalance, 0)
      const secondAccountBalance = await this.token.balanceOf(owner1)
      assert.equal(secondAccountBalance, 2)
    })

    it('should throw an error when trying to assign existing parcel', async function _() {
      await this.token.mint(owner1, [tile1], { from: owner0}).should.be.rejectedWith(EVMRevert)
    })

    it('should throw an error when trying to assign existing token in new parcel', async function _() {
      await this.token.mint(owner1, [tile2, tile1], { from: owner0}).should.be.rejectedWith(EVMRevert)
    })
    
    // TODO move to fixed/dynamic minting utility:
    // it('should mint valid quadkeys', async function _() {
    //   //Invalid zoom level minting from public endpoint
    //   const t23 = (new BinaryQuadkey.fromQuadkey("03310102023223201112221")).toString()
    //   await this.token.mint(owner1, [t23], { from: owner0}).should.be.rejectedWith(EVMRevert)

    //   const t17 = (new BinaryQuadkey.fromQuadkey("03310102023223201")).toString()
    //   await this.token.mint(owner1, [t17], { from: owner0}).should.be.rejectedWith(EVMRevert)
      
    //   const t16 = (new BinaryQuadkey.fromQuadkey("0123012301230123")).toString()
    //   await this.token.mint(owner1, [t16], { from: owner0}).should.be.fulfilled

    // })

    it('should log valid minting events', async function _() {
      const qk = new BinaryQuadkey.fromQuadkey("0123012301230123")
      const t16 = qk.toString()
      // console.log("FIRST", qk)
      // console.log("SECOND", qk.toString())
      // console.log("THIRD", qk.toQuadkey())
      const tx = await this.token.mint(owner1, [t16], { from: owner0}).should.be.fulfilled
      const logs = tx.logs
      logs.length.should.be.equal(1);
      logs[0].args._from.should.be.equal(ZERO_ADDRESS);
      logs[0].args._to.should.be.equal(owner1);
      const resultToken = logs[0].args._tokenId
      resultToken.should.be.bignumber.equal(t16);
      const is16 = await this.qk.isZoom(resultToken.toString(), 16);
      is16.should.be.true
      const quadKeyResult = new BinaryQuadkey.fromUInt64(Long.fromString(resultToken.toString()))
      quadKeyResult.toQuadkey().should.be.equal("0123012301230123")
    })
  })

  it('should support ERC-721', async function _() {
    const ERC721 = await this.token.InterfaceSignature_ERC721()
    const result = await this.token.supportsInterface(ERC721.toString())
    assert.equal(result, true)
  })

  it('should be able to query owner of land after it is assigned', async function _() {
    await this.token.mint(owner1, [tile2], { from: owner0})
    const result = await this.token.ownerOf(tile2)
    assert.equal(owner1, result)
  })

 

  it('should be able to build a unique group id', async function _() {
    const inOrder = [1, 2, 3, 4, 5]
    await this.token.uniqueTokenGroupId(inOrder).should.be.fulfilled

    const outOfOrder = [3, 2]
    await this.token.uniqueTokenGroupId(outOfOrder).should.be.rejectedWith(EVMRevert)

    const duplicate = [1, 2, 3, 4, 4, 5]
    await this.token.uniqueTokenGroupId(duplicate).should.be.rejectedWith(EVMRevert)
  })

  // TODO Move to Batchable721Token testing
  describe('Batching', () => {
    const numTokens = 50

    it(`should be able to transfer at least ${numTokens}`, async function _() {
      let quadKeys = generateQuadKeys(numTokens, "0123012301230123", [])
      const tokens = quadKeys.map(i => (new BinaryQuadkey.fromQuadkey(i)).toString())
      await this.token.mint(owner1, tokens, { from: owner0}).should.be.fulfilled
      await this.token.approveMany(owner2, tokens, { from: owner1 }).should.be.fulfilled
      await this.token.transferFromMany(owner1, recipient, tokens, { from: owner2 }).should.be.fulfilled
      const balance = await this.token.balanceOf(recipient)
      balance.should.be.bignumber.equal(numTokens)
    })

    const mintableMax = 52

    it(`should be able to mint at least ${mintableMax}`, async function _() {
      const tokens = Array(mintableMax).fill().map((x, i) => i)
      const tx = await this.token.mint(owner1, tokens, { from: owner0 }).should.be.fulfilled
    })

    it('should be able to cheaply iterate thousands of tokens', async function () {
      this.timeout(0)
      // Tested as high as 300
      // let numGroups = 300
      const numGroups = 10
      for (let j = 0; j < numGroups; j++) {
        const tokens = Array(mintableMax).fill().map((x, i) => i + (j * mintableMax))
        const tx = await this.token.mint(owner1, tokens, { from: owner0, gasPrice: 0 }).should.be.fulfilled
      }
      const balance = await this.token.balanceOf(owner1)
      assert.equal(balance, numGroups * mintableMax)

      for (let k = 100; k < 200; k++) {
        await this.token.tokenOfOwnerByIndex(owner1, k).should.be.fulfilled
      }
    })
  })
})

