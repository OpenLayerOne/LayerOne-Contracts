import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert'
import EVMRevert from 'zeppelin-solidity/test/helpers/EVMRevert'
import { advanceBlock } from 'zeppelin-solidity/test/helpers/advanceToBlock'

const QuadToken = artifacts.require('QuadToken.sol')
const BigNumber = web3.BigNumber
const BinaryQuadkey = require('binaryquadkey')

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('QuadToken', ([_, owner0, owner1, owner2, recipient]) => {
  const qk1 = new BinaryQuadkey.fromQuadkey("0231010202322300");
  const qk2 = new BinaryQuadkey.fromQuadkey("0331010202322300");
  const tile1 = qk1.toString()
  const tile2 = qk2.toString()
  const tile3 = (new BinaryQuadkey.fromQuadkey("0331010202322320")).toString()

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
      await this.token.publicMinting(owner0, [tile1])
    })

    it('should return the correct totalSupply after minting a tile', async function _() {
      const totalSupply = await this.token.totalSupply()
      assert.equal(totalSupply.toDigits(), 1)
    })

    it('should return correct balances after transfer', async function _() {
      await this.token.publicMinting(owner1, [tile2])
      const token = await this.token.tokenOfOwnerByIndex(owner0, 0)
      await this.token.transferFromMany(owner0, owner1, [tile1], { from: owner0 })
      const firstAccountBalance = await this.token.balanceOf(owner0)
      assert.equal(firstAccountBalance, 0)
      const secondAccountBalance = await this.token.balanceOf(owner1)
      assert.equal(secondAccountBalance, 2)
    })

    it('should throw an error when trying to assign existing parcel', async function _() {
      await this.token.publicMinting(owner1, [tile1]).should.be.rejectedWith(EVMRevert)
    })

    it('should throw an error when trying to assign existing token in new parcel', async function _() {
      await this.token.publicMinting(owner1, [tile2, tile1]).should.be.rejectedWith(EVMRevert)
    })
    // it('should be able to assign multiple parcels', async function _() {

    // })
  })

  it('should support ERC-721', async function _() {
    const ERC721 = await this.token.InterfaceSignature_ERC721()
    const result = await this.token.supportsInterface(ERC721.toString())
    assert.equal(result, true)
  })

  it('should be able to query owner of land after it is assigned', async function _() {
    await this.token.publicMinting(owner1, [tile2])
    const result = await this.token.ownerOf(tile2)
    assert.equal(owner1, result)
  })

  describe('Metadata', () => {
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
  })

  it('should be able to build a unique group id', async function _() {
    const inOrder = [1, 2, 3, 4, 5]
    await this.token.uniqueTokenGroupId(inOrder).should.be.fulfilled

    const outOfOrder = [3, 2]
    await this.token.uniqueTokenGroupId(outOfOrder).should.be.rejectedWith(EVMRevert)

    const duplicate = [1, 2, 3, 4, 4, 5]
    await this.token.uniqueTokenGroupId(duplicate).should.be.rejectedWith(EVMRevert)
  })

  // TODO Batchable721Token testing
  // describe('Batching', () => {
  //   const numTokens = 48

  //   it(`should be able to transfer at least ${numTokens}`, async function _() {
  //     const tokens = Array(numTokens).fill().map((x, i) => i)
  //     await this.token.publicMinting(owner1, [tile2])
  //     await this.token.approveMany(owner2, tokens, { from: owner1 }).should.be.fulfilled
  //     await this.token.transferFromMany(owner1, recipient, tokens, { from: owner2 }).should.be.fulfilled
  //     const balance = await this.token.balanceOf(recipient)
  //     balance.should.be.bignumber.equal(numTokens)
  //   })


  //   const mintableMax = 52

  //   it(`should be able to mint at least ${mintableMax}`, async function _() {
  //     const tokens = Array(mintableMax).fill().map((x, i) => i)
  //     const tx = await this.token.mint(owner1, tokens, { from: owner0 })
  //   })

  //   it('should be able to cheaply iterate thousands of tokens', async function () {
  //     this.timeout(0)
  //     // Tested as high as 300
  //     // let numGroups = 300
  //     const numGroups = 10
  //     for (let j = 0; j < numGroups; j++) {
  //       const tokens = Array(mintableMax).fill().map((x, i) => i + (j * mintableMax))
  //       const tx = await this.token.mint(owner1, tokens, { from: owner0, gasPrice: 0 })
  //     }
  //     const balance = await this.token.balanceOf(owner1)
  //     assert.equal(balance, numGroups * mintableMax)

  //     for (let k = 100; k < 200; k++) {
  //       await this.token.tokenOfOwnerByIndex(owner1, k).should.be.fulfilled
  //     }
  //   })
  // })
})

