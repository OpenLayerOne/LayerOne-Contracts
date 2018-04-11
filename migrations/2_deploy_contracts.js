const Capped721DutchCrowdsale = artifacts.require('Capped721DutchCrowdsale.sol')
const LayerOneLand = artifacts.require('LayerOneLand.sol')
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
const gas = 6721975

const makeQuadKey = function (token) {
  return new BinaryQuadkey.fromQuadkey(token).toString()
}

async function deployLandSale(deployer, landSaleOwner) {
  const cap = ether(10000)
  const presaleStart = latestTime() + duration.days(1)
  const presaleEnd = presaleStart + duration.days(1)
  const startTime = presaleEnd + duration.seconds(1)
  const endTime = startTime + duration.days(35)
  const startPrice = ether(0.035)
  const endPrice = ether(0.005)
  const presaleSpots = 5000
  const land = LayerOneLand.address

  return deployer.deploy(
    Capped721DutchCrowdsale,
    cap,
    presaleStart,
    presaleEnd,
    startTime,
    endTime,
    startPrice,
    endPrice,
    landSaleOwner,
    land,
    presaleSpots,
    { from: landSaleOwner, gas })
}


async function deployPromoUtility(deployer, landSaleOwner) {
  const address = LayerOneLand.address
  return deployer.deploy(PromoMintingUtility, address, { from: landSaleOwner, gas })
}


async function deployLibraries(deployer) {
  return deployer.deploy([Quadkey, DutchAuction]).then(async () => {
    return deployer.link(Quadkey, [LayerOneLand, Capped721DutchCrowdsale])
  }).then(() => {
    return deployer.link(DutchAuction, [Capped721DutchCrowdsale])
  })
}

module.exports = async function _(deployer, network, [owner]) {
  return deployLibraries(deployer).then(async () => {
    return deployer.deploy(LayerOneLand, { from: owner, gas })
  }).then(() => {
    return deployLandSale(deployer, owner)
  }).catch(console.log)
}
