import ether from 'zeppelin-solidity/test/helpers/ether'
import { advanceBlock } from 'zeppelin-solidity/test/helpers/advanceToBlock'
import { increaseTimeTo, duration } from 'zeppelin-solidity/test/helpers/increaseTime'
import latestTime from 'zeppelin-solidity/test/helpers/latestTime'
import EVMRevert from 'zeppelin-solidity/test/helpers/EVMRevert'

const BigNumber = web3.BigNumber
const BinaryQuadkey = require('binaryquadkey')

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

const Crowdsale = artifacts.require('Crowdsale721')
const Token = artifacts.require('Batchable721Token')

const t1 = new BinaryQuadkey.fromQuadkey('02310102301')
const t2 = new BinaryQuadkey.fromQuadkey('02310102302')
const t3 = new BinaryQuadkey.fromQuadkey('02310102303')
const c1 = new BinaryQuadkey.fromQuadkey('02310102')

const tokens = [t1.toString(), t2.toString(), t3.toString()]
contract('Crowdsale', ([_, nftOwner, investor, purchaser, crowdsaleWallet]) => {
  const gas = 6721970

  const expectedTokenAmount = tokens.length

  before(async () => {
    // Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
    await advanceBlock()
  })

  beforeEach(async function () {
    const price = ether(0.05)

    this.startTime = latestTime() + duration.days(10)
    this.afterStartTime = this.startTime + duration.seconds(1)
    this.endTime = this.startTime + duration.weeks(4) + duration.days(3)
    this.afterEndTime = this.endTime + duration.seconds(1)
    this.token = await Token.new({ from: nftOwner, gasPrice: 0 })
    this.crowdsale = await Crowdsale.new(this.startTime, this.endTime, price, crowdsaleWallet, this.token.address, { from: nftOwner, gasPrice: 0 })
    await this.token.setApprovedMinter(this.crowdsale.address, true, { from: nftOwner, gasPrice: 0 })
    this.cityId = c1.toString()
    this.price = await this.crowdsale.startPrice()
    this.cost = this.price * tokens.length
  })

  it('should be ended only after end', async function () {
    let ended = await this.crowdsale.hasEnded()
    ended.should.equal(false)
    await increaseTimeTo(this.afterEndTime)
    ended = await this.crowdsale.hasEnded()
    ended.should.equal(true)
  })

  describe('accepting payments', () => {
    it('should reject payments before start', async function () {
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { from: purchaser, value: this.cost }).should.be.rejectedWith(EVMRevert)
    })

    it('should accept payments after start', async function () {
      await increaseTimeTo(this.afterStartTime)
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: purchaser }).should.be.fulfilled
    })

    it('should reject payments after end', async function () {
      await increaseTimeTo(this.afterEndTime)
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: purchaser }).should.be.rejectedWith(EVMRevert)
    })
  })

  describe('high-level purchase', () => {
    beforeEach(async function () {
      await increaseTimeTo(this.startTime)
    })

    it('should log purchase', async function () {
      const { logs } = await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: investor })
      const event = logs.find(e => e.event === 'LandsalePurchase')

      should.exist(event)
      event.args.purchaser.should.equal(investor)
      event.args.beneficiary.should.equal(investor)
      event.args.value.should.be.bignumber.equal(this.cost)
      event.args.numTokens.should.be.bignumber.equal(tokens.length)
    })

    it('should increase totalSupply', async function () {
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: investor })
      const totalSupply = await this.token.totalSupply()
      totalSupply.should.be.bignumber.equal(expectedTokenAmount)
    })

    it('should assign tokens to sender', async function () {
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: investor })
      const balance = await this.token.balanceOf(investor)
      balance.should.be.bignumber.equal(expectedTokenAmount)
    })

    it('should forward funds to the owner of the contract', async function () {
      const pre = web3.eth.getBalance(crowdsaleWallet)
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: investor })
      const post = web3.eth.getBalance(crowdsaleWallet)
      post.minus(pre).should.be.bignumber.equal(this.cost)
    })
  })

  describe('low-level purchase', () => {
    beforeEach(async function () {
      await increaseTimeTo(this.startTime)
    })

    it('should log purchase', async function () {
      const { logs } = await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: purchaser })

      const event = logs.find(e => e.event === 'LandsalePurchase')

      should.exist(event)
      event.args.purchaser.should.equal(purchaser)
      event.args.beneficiary.should.equal(investor)
      event.args.value.should.be.bignumber.equal(this.cost)
      event.args.numTokens.should.be.bignumber.equal(tokens.length)
    })

    it('should increase totalSupply', async function () {
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: purchaser })
      const totalSupply = await this.token.totalSupply()
      totalSupply.should.be.bignumber.equal(expectedTokenAmount)
    })

    it('should assign tokens to beneficiary', async function () {
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: purchaser })
      const balance = await this.token.balanceOf(investor)
      balance.should.be.bignumber.equal(expectedTokenAmount)
    })

    it('should forward funds to the contract owner', async function () {
      const pre = web3.eth.getBalance(crowdsaleWallet)
      await this.crowdsale.buyTokens(tokens, this.cityId, investor, { value: this.cost, from: purchaser })
      const post = web3.eth.getBalance(crowdsaleWallet)
      post.minus(pre).should.be.bignumber.equal(this.cost)
    })
  })
})
