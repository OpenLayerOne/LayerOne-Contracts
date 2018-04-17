const Capped721DutchCrowdsale = artifacts.require('Capped721DutchCrowdsale.sol')
const QuadToken = artifacts.require('QuadToken.sol')
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

async function deployLandSale(deployer, landSaleOwner) {
  const cap = ether(10000)
  const startTime = latestTime() + duration.seconds(1)
  const endTime = startTime + duration.days(16)
  const startPrice = ether(1)
  const endPrice = ether(0)
  const minTilesSold = 100000
  const land = QuadToken.address
  return deployer.deploy(
    Capped721DutchCrowdsale,
    minTilesSold,
    cap,
    startTime,
    endTime,
    startPrice,
    endPrice,
    landSaleOwner,
    land,
    { from: landSaleOwner }).then(crowdsale => {
      return QuadToken.deployed()
    }).then(token => {
      return token.setApprovedMinter(Capped721DutchCrowdsale.address, true, {from: landSaleOwner})
    })
}


async function deployPromoUtility(deployer, landSaleOwner) {
  const address = QuadToken.address
  return deployer.deploy(PromoMintingUtility, address, { from: landSaleOwner })
}


async function deployLibraries(deployer) {
  return deployer.deploy([Quadkey, DutchAuction]).then(async () => {
    return deployer.link(Quadkey, [QuadToken, Capped721DutchCrowdsale])
  }).then(() => {
    return deployer.link(DutchAuction, [Capped721DutchCrowdsale])
  })
}

module.exports = async function _(deployer, network, [owner]) {
  return deployLibraries(deployer).then(async () => {
    return deployer.deploy(QuadToken, { from: owner })
  }).then(() => {
    return deployLandSale(deployer, owner)
  }).catch(console.log)
}
