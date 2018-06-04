const LandRushCrowdsale = artifacts.require('LandRushCrowdsale.sol')
const QuadToken = artifacts.require('QuadToken.sol')
const LRGToken = artifacts.require('LRGToken.sol')
const PromoMintingUtility = artifacts.require('PromoMintingUtility.sol')
const BinaryQuadkey = require('binaryquadkey')

const Quadkey = artifacts.require('QuadkeyLib.sol')
const DutchAuction = artifacts.require('DutchAuctionLib.sol')

const duration = {
  seconds(val) { return val },
  minutes(val) { return val * this.seconds(60) },
  hours(val) { return val * this.minutes(60) },
  days(val) { return val * this.hours(24) },
  weeks(val) { return val * this.days(7) },
  years(val) { return val * this.days(365) },
}

function latestTime() {
  return web3.eth.getBlock('latest').timestamp
}

function ether(n) {
  return new web3.BigNumber(web3.toWei(n, 'ether'))
}

const BigNumber = web3.BigNumber
const gas = 4000000

const makeQuadKey = function (token) {
  return new BinaryQuadkey.fromQuadkey(token).toString()
}

function deployLandSale(deployer, landSaleOwner) {
  const startTime = latestTime() + duration.seconds(1)
  const endTime = startTime + duration.days(21)
  const startPrice = ether(.5)
  const endPrice = ether(0.001)
  const minTilesSold = 100000
  const land = QuadToken.address
  const gold = LRGToken.address
  return deployer.deploy(
    LandRushCrowdsale,
    minTilesSold,
    startTime,
    endTime,
    startPrice,
    endPrice,
    landSaleOwner,
    land,
    gold,
    { from: landSaleOwner })
}


function deployPromoUtility(deployer, landSaleOwner) {
  const address = QuadToken.address
  return deployer.deploy(PromoMintingUtility, address, { from: landSaleOwner })
}


function deployLibraries(deployer) {
  return deployer.deploy([Quadkey, DutchAuction]).then(() => {
    return deployer.link(Quadkey, [QuadToken, LandRushCrowdsale])
  }).then(() => {
    return deployer.link(DutchAuction, [LandRushCrowdsale])
  })
}

module.exports = function _(deployer, network, [owner1, owner2, owner3]) {
  let goldContract = undefined
  let landContract = undefined
  let quadTokenOwner = owner1
  let lrgTokenOwner = owner1
  let landRushOwner = owner1
  let nameProtocolOwner = lrgTokenOwner
  console.log("QuadToken owner", quadTokenOwner)
  console.log("LRGToken owner", lrgTokenOwner)
  console.log("LandRushCrowdsale owner", landRushOwner)

  return deployLibraries(deployer).then(() => {
    return deployer.deploy(QuadToken, { from: quadTokenOwner })
  }).then(() => {
    return deployer.deploy(LRGToken, { from: lrgTokenOwner })
  }).then((goldToken) => {
    return deployLandSale(deployer, landRushOwner)
  }).then(() => {
    return QuadToken.deployed()
  }).then((contract) => {
    landContract = contract
    return LRGToken.deployed()
  }).then(contract => {
    goldContract = contract
    return landContract.setApprovedMinter(LandRushCrowdsale.address, true, {from: quadTokenOwner})
  }).then(() => {
    return landContract.createMetadataProtocol(1, ether(2), 0, lrgTokenOwner, nameProtocolOwner, goldContract.address)
  }).then((contract) => {
    return goldContract.totalSupply()
  }).then(supply => {
    console.log("LRG SUPPLY", supply.toString())
    return goldContract.approve(LandRushCrowdsale.address, supply/2, {from: lrgTokenOwner})
  })
  .catch(console.log)
}
