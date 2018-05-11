pragma solidity ^0.4.21;

import "./Crowdsale721.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../libraries/QuadkeyLib.sol";
import "../libraries/DutchAuctionLib.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../tokens/LRGToken.sol";

contract LandRushCrowdsale is Crowdsale721, Ownable {

    using SafeMath for uint256;
    
    // Number of remaining whitelisted user slots
    uint32 public minTilesSold = 100000;
    LRGToken public goldContract_;

    uint256 public endPrice;

    /*
        The crowdsale for Layer One 
        @param _cap Has a cap, so that it ends when cap reached
        @param _landsaleStart when the first public purchase period should begin
        all dates will be relative this beginning.
        @param _landsaleEnd when all crowdsale functionality is over
        @param _wallet the destination of purchase funds
        @param _nftContract The contract that holds the tile ownership information
    */
    function LandRushCrowdsale(
        uint32 _minTilesSold,
        uint256 _landsaleStart,
        uint256 _landsaleEnd,
        uint256 _startPrice,
        uint256 _endPrice,
        address _wallet,
        address _nftContract,
        address _goldContract
    ) 
        Crowdsale721(_landsaleStart, _landsaleEnd, _startPrice, _wallet, _nftContract)
        public 
    {
        goldContract_ = LRGToken(_goldContract);
        minTilesSold = _minTilesSold;
        endPrice = _endPrice;
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return nftContract_.totalSupply() >= minTilesSold;
    }

    function validPurchase(uint256[] _tokenIds) 
        internal 
        view 
        returns (bool) 
    {

        // make sure we are not ended
        require(hasEnded() == false);

        for (uint32 x = 0; x < _tokenIds.length; x++) {
            // require valid zoom 16 quad key
            require(QuadkeyLib.isZoom(_tokenIds[x], 16));
        }

        bool correctPayment = msg.value >= price(_tokenIds);
        bool withinPeriod = now >= startTime;

        return correctPayment && withinPeriod;
    }

    function numGoldToDistribute() 
        public
        view
        returns (uint64)
    {
        uint256 supply = nftContract_.totalSupply();
        if (supply < 20000) {
            return 2000;
        } else if (supply < 40000) {
            return 1400;
        } else if (supply < 60000) {
            return 900;
        } else if (supply < 80000) {
            return 500;
        }
        return 200;
    }

    // low level token purchase function
  function buyTokens(
    uint256[] _tokenIds,
    address _beneficiary
  ) 
    public 
    payable 
  {
    super.buyTokens(_tokenIds, _beneficiary);
    
    // transfer Gold Reward to beneficiary
    goldContract_.transferFrom(owner, _beneficiary, _tokenIds.length.mul(numGoldToDistribute()));
  }

    // calculates dutch auction price from start of presale to now
    function price(uint256[] _tokenIds) 
        public
        view 
        returns (uint256) 
    {
        // uint256 pricePerToken =1;
        uint256 pricePerToken = DutchAuctionLib.dutchAuctionPrice(
            startTime,
            endTime.sub(startTime),
            startPrice,
            endPrice
        );

        return pricePerToken.mul(_tokenIds.length);
    }
}