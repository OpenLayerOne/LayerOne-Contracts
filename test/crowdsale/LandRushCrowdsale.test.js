import assertRevert from 'openzeppelin-solidity/test/helpers/assertRevert'
import EVMRevert from 'openzeppelin-solidity/test/helpers/EVMRevert'
import ether from 'openzeppelin-solidity/test/helpers/ether'
import latestTime from 'openzeppelin-solidity/test/helpers/latestTime'
import { increaseTimeTo, duration } from 'openzeppelin-solidity/test/helpers/increaseTime'
import { advanceBlock } from 'openzeppelin-solidity/test/helpers/advanceToBlock'

const BinaryQuadkey = require('binaryquadkey')

const LandRushCrowdsale = artifacts.require('LandRushCrowdsale.sol')
const QuadToken = artifacts.require('QuadToken.sol')
const LRGToken = artifacts.require('LRGToken.sol')
const BigNumber = web3.BigNumber

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('LandRushCrowdsale', ([_, crowdsaleOwner, nftOwner, crowdsaleWallet, tokenOwner, presaleUser1, presaleUser2, presaleUser3]) => {

  const t1 = (new BinaryQuadkey.fromQuadkey('0231010223123111')).toString()
  const t2 = (new BinaryQuadkey.fromQuadkey('0231010223123121')).toString()
  const t3 = (new BinaryQuadkey.fromQuadkey('0231010223123112')).toString()
  const t4 = (new BinaryQuadkey.fromQuadkey('0231010223123110')).toString()
  const t5 = (new BinaryQuadkey.fromQuadkey('0231010223121110')).toString()

  const t21 = (new BinaryQuadkey.fromQuadkey('0231010323123111')).toString()
  const t22 = (new BinaryQuadkey.fromQuadkey('0231010323123121')).toString()
  const t23 = (new BinaryQuadkey.fromQuadkey('0231010323123112')).toString()
  
  before(async () => {
    // Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
    await advanceBlock()
  })

  beforeEach(async function _() {
    this.startTime = latestTime()
    this.afterStart = this.startTime + duration.seconds(1)
    this.endTime = this.startTime + duration.weeks(9)
    this.afterEndTime = this.endTime + duration.seconds(1)
    this.token = await QuadToken.new({ from: nftOwner, gasPrice: 0 })
    this.lrgToken = await LRGToken.new({ from: nftOwner, gasPrice: 0 })
    this.startPrice = ether(0.5)
    this.endPrice = ether(0.001)
    this.tilesToSell = 5
    this.crowdsale = await LandRushCrowdsale.new(
      this.tilesToSell,
      this.startTime,
      this.endTime,
      this.startPrice,
      this.endPrice,
      crowdsaleWallet,
      this.token.address,
      this.lrgToken.address,
      { from: nftOwner, gasPrice: 0 })
      this.pricePerToken = await this.crowdsale.price([t1])
      
      await this.lrgToken.approve(this.crowdsale.address, 200000000, { from: nftOwner, gasPrice: 0 } )
      await this.token.setApprovedMinter(this.crowdsale.address, true, { from: nftOwner, gasPrice: 0 })
  })

  describe('purchase validation', () => {

    it('should have correct price at beginning and halfway through and at end of auction', async function _() {
      let c1 = await this.crowdsale.price([t1])
      c1 = await this.crowdsale.price([t1])
      c1.should.be.bignumber.to.be.at.most(this.startPrice)
      c1.should.be.bignumber.greaterThan(this.startPrice - ether(0.00001))
      await increaseTimeTo((this.startTime + this.endTime) / 2)
      let c2 = await this.crowdsale.price([t1])
      c2.should.be.bignumber.to.be.at.most((this.startPrice.add(this.endPrice)).div(2))
      c2.should.be.bignumber.greaterThan((this.startPrice.add(this.endPrice)).div(2) - ether(0.00001))
      await increaseTimeTo(this.endTime)
      c2 = await this.crowdsale.price([t21])
      c2.should.be.bignumber.equal(this.endPrice)
    })
  })

  describe('ending', () => {

    it('should not end after end date', async function () {
      let ended = await this.crowdsale.hasEnded()
      ended.should.equal(false)
      await increaseTimeTo(this.afterEndTime)
      ended = await this.crowdsale.hasEnded()
      ended.should.equal(false)
    })

    it('should be ended if token limit is reached', async function () {
      await increaseTimeTo(this.afterEndTime)
      let owner = await this.crowdsale.owner()
      await this.crowdsale.buyTokens([t1, t2, t3, t4, t5], tokenOwner, { value: this.pricePerToken * 5}).should.be.fulfilled

      const hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(true)
      await this.crowdsale.buyTokens([t4, t5], tokenOwner, { value: this.pricePerToken * 2 }).should.not.be.fulfilled
    })
  })


})
