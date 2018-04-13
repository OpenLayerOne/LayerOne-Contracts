import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert'
import EVMRevert from 'zeppelin-solidity/test/helpers/EVMRevert'
import ether from 'zeppelin-solidity/test/helpers/ether'
import latestTime from 'zeppelin-solidity/test/helpers/latestTime'
import { increaseTimeTo, duration } from 'zeppelin-solidity/test/helpers/increaseTime'

const BinaryQuadkey = require('binaryquadkey')

const Capped721DutchCrowdsale = artifacts.require('Capped721DutchCrowdsale.sol')
const QuadToken = artifacts.require('QuadToken.sol')
const BigNumber = web3.BigNumber

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

contract('Capped721DutchCrowdsale', ([_, crowdsaleOwner, nftOwner, crowdsaleWallet, tokenOwner, presaleUser1, presaleUser2, presaleUser3]) => {
  const cap = ether(5)
  const lessThanCap = ether(2)
  const city1 = (new BinaryQuadkey.fromQuadkey('02310102')).toString()
  const city2 = (new BinaryQuadkey.fromQuadkey('02310103')).toString()
  const t1 = (new BinaryQuadkey.fromQuadkey('0231010223123111')).toString()
  const t2 = (new BinaryQuadkey.fromQuadkey('0231010223123121')).toString()
  const t3 = (new BinaryQuadkey.fromQuadkey('0231010223123112')).toString()
  const t4 = (new BinaryQuadkey.fromQuadkey('0231010223123110')).toString()
  const t5 = (new BinaryQuadkey.fromQuadkey('0231010223121110')).toString()

  const t21 = (new BinaryQuadkey.fromQuadkey('0231010323123111')).toString()
  const t22 = (new BinaryQuadkey.fromQuadkey('0231010323123121')).toString()
  const t23 = (new BinaryQuadkey.fromQuadkey('0231010323123112')).toString()

  const invalidToken = (new BinaryQuadkey.fromQuadkey('0221010223123110')).toString()

  beforeEach(async function _() {
    this.beforePresale = latestTime() + duration.minutes(2)
    this.presaleStart = this.beforePresale + duration.days(7)
    this.presaleEnd = this.presaleStart + duration.days(1)
    this.startTime = this.presaleEnd
    this.afterStart = this.startTime + duration.seconds(1)
    this.endTime = this.startTime + duration.weeks(9)
    this.afterEndTime = this.endTime + duration.seconds(1)
    this.token = await QuadToken.new({ from: nftOwner, gasPrice: 0 })
    this.startPrice = ether(2)
    this.endPrice = ether(1)
    this.presaleSpots = 2
    this.crowdsale = await Capped721DutchCrowdsale.new(
      cap,
      this.presaleStart,
      this.presaleEnd,
      this.startTime,
      this.endTime,
      this.startPrice,
      this.endPrice,
      crowdsaleWallet,
      this.token.address,
      this.presaleSpots,
      { from: crowdsaleOwner, gasPrice: 0 })
    await this.token.setApprovedMinter(this.crowdsale.address, true, { from: nftOwner, gasPrice: 0 })
  })

  describe('purchase validation', () => {
    beforeEach(async () => {

    })


    it('should have correct price at beginning and halfway through and at end of auction', async function _() {
      let c1 = await this.crowdsale.price([t1])
      await increaseTimeTo(this.startTime)
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
    it('should be ended only after end', async function () {
      let ended = await this.crowdsale.hasEnded()
      ended.should.equal(false)
      await increaseTimeTo(this.afterEndTime)
      ended = await this.crowdsale.hasEnded()
      ended.should.equal(true)
    })

    beforeEach(async function () {
      await increaseTimeTo(this.afterStart)
      this.pricePerToken = await this.crowdsale.price([t1])
    })

    it('should not be ended if under cap', async function () {
      let hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(false)
      await this.crowdsale.buyTokens([t1], tokenOwner, { value: this.pricePerToken })
      hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(false)
    })

    it('should be ended if cap reached', async function () {
      await this.crowdsale.buyTokens([t1, t2, t3], tokenOwner, { value: this.pricePerToken * 3 }).should.be.fulfilled
      const hasEnded = await this.crowdsale.hasEnded()
      hasEnded.should.equal(true)
      await this.crowdsale.buyTokens([t4, t5], tokenOwner, { value: this.pricePerToken * 2 }).should.not.be.fulfilled
    })
  })

  describe('reservePresaleSpot', () => {
    beforeEach(async function () {
      this.pricePerToken = await this.crowdsale.price([t1])
    })

    it('should allow reserving presale spot in presale period', async function () {
      await increaseTimeTo(this.beforePresale)
      await this.crowdsale.reservePresaleSpot({ from: presaleUser1 }).should.be.fulfilled
    })

    it('should block reserving presale spot before or after period', async function () {
      await increaseTimeTo(this.presaleStart)
      await this.crowdsale.reservePresaleSpot({ from: presaleUser1 }).should.not.be.fulfilled
    })

    it('should block reserving presale when no more spots remaining', async function () {
      await increaseTimeTo(this.beforePresale)
      await this.crowdsale.reservePresaleSpot({ from: presaleUser1 }).should.be.fulfilled
      await this.crowdsale.reservePresaleSpot({ from: presaleUser2 }).should.be.fulfilled
      await this.crowdsale.reservePresaleSpot({ from: presaleUser3 }).should.not.be.fulfilled
    })

    it('should transmit event when presale spot is reserved', async function () {
      await increaseTimeTo(this.beforePresale)
      const { logs } = await this.crowdsale.reservePresaleSpot({ from: presaleUser1 }).should.be.fulfilled
      const event = logs.find(e => e.event === 'PresaleSpotReserved')
      should.exist(event)
      event.args.user.should.equal(presaleUser1)
      event.args.presaleSpotsTaken.should.be.bignumber.equal(1)
    })
  })

  describe('presale whitelist purchase', () => {
    beforeEach(async function () {
      this.pricePerToken = await this.crowdsale.price([t1])
    })

    it('should allow only whitelisted users to purchase tokens in presale', async function () {
      await increaseTimeTo(this.beforePresale)
      await this.crowdsale.reservePresaleSpot({ from: presaleUser1 }).should.be.fulfilled
      await increaseTimeTo(this.presaleStart)
      await this.crowdsale.buyTokens([t1], tokenOwner, { value: this.pricePerToken, from: presaleUser1 }).should.be.fulfilled
    })

    it('should block users to purchase in presale if not current presale', async function () {
      await increaseTimeTo(this.beforePresale)
      await this.crowdsale.reservePresaleSpot({ from: presaleUser1 }).should.be.fulfilled
      await this.crowdsale.buyTokens([t1], tokenOwner, { value: this.pricePerToken, from: presaleUser1 }).should.not.be.fulfilled
      await increaseTimeTo(this.presaleStart)
      await this.crowdsale.buyTokens([t2], tokenOwner, { value: this.pricePerToken, from: presaleUser1 }).should.be.fulfilled
    })
  })
})
