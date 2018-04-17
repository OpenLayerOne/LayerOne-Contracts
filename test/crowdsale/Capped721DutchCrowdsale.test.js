import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert'
import EVMRevert from 'zeppelin-solidity/test/helpers/EVMRevert'
import ether from 'zeppelin-solidity/test/helpers/ether'
import latestTime from 'zeppelin-solidity/test/helpers/latestTime'
import { increaseTimeTo, duration } from 'zeppelin-solidity/test/helpers/increaseTime'
import { advanceBlock } from 'zeppelin-solidity/test/helpers/advanceToBlock'

const BinaryQuadkey = require('binaryquadkey')

const Capped721DutchCrowdsale = artifacts.require('Capped721DutchCrowdsale.sol')
const QuadToken = artifacts.require('QuadToken.sol')
const BigNumber = web3.BigNumber

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('Capped721DutchCrowdsale', ([_, crowdsaleOwner, nftOwner, crowdsaleWallet, tokenOwner, presaleUser1, presaleUser2, presaleUser3]) => {
  const cap = ether(3)
  const lessThanCap = ether(2)

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
    this.startPrice = ether(1)
    this.endPrice = ether(0)
    this.tilesToSell = 5
    this.crowdsale = await Capped721DutchCrowdsale.new(
      this.tilesToSell,
      cap,
      this.startTime,
      this.endTime,
      this.startPrice,
      this.endPrice,
      crowdsaleWallet,
      this.token.address,
      { from: crowdsaleOwner, gasPrice: 0 })
      this.pricePerToken = await this.crowdsale.price([t1])

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

    it('should not be ended if under cap', async function () {
      let hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(false)
      await this.crowdsale.buyTokens([t1], tokenOwner, { value: this.pricePerToken }).should.be.fulfilled
      hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(false)
    })

    it('should be ended if cap reached', async function () {
      await this.crowdsale.buyTokens([t1, t2, t3], tokenOwner, { value: this.pricePerToken * 4 }).should.be.fulfilled
      const hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(true)
      await this.crowdsale.buyTokens([t4, t5], tokenOwner, { value: this.pricePerToken * 2 }).should.not.be.fulfilled
    })

    it('should be ended if token limit is reached', async function () {
      await increaseTimeTo(this.afterEndTime)

      await this.crowdsale.buyTokens([t1, t2, t3, t4, t5], tokenOwner, { value: 0 }).should.be.fulfilled

      const hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(true)
      await this.crowdsale.buyTokens([t4, t5], tokenOwner, { value: this.pricePerToken * 2 }).should.not.be.fulfilled
    })
  })


})
