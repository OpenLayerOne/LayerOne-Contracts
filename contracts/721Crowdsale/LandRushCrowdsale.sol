pragma solidity ^0.4.21;

import "./Crowdsale721.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../libraries/QuadkeyLib.sol";
import "../libraries/DutchAuctionLib.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../tokens/LRGToken.sol";

contract LandRushCrowdsale is Crowdsale721, Ownable {

    using SafeMath for uint256;
    
    // Number of Tiles to be sold in the Land Rush Crowdsale
    uint32 public minTilesSold = 100000;
    LRGToken public goldContract_;
    uint256 public endPrice;
    /*
        The Land Rush crowdsale for Layer One 
        @param _minTilesSold The number of tiles to sell in the crowdsale
        @param _landsaleStart when the first public purchase period should begin
        all dates will be relative this beginning.
        @param _landsaleEnd The price will drop linearly to endPrice at this date
        @param _startPrice The starting price of crowdsale
        @param _endPrice The price will drop linearly to this price
        @param _wallet the destination of purchase funds
        @param _nftContract The contract that holds the tile ownership information
        @param _goldContract The contract that holds the LRG ownership information
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

    /*
        overriding Crowdsale hasEnded to limit to the number of tiles sold
        @return true if total supply is over the minTilesSold
    */
    function hasEnded() public view returns (bool) {
        return nftContract_.totalSupply() >= minTilesSold;
    }

    /*
        Validates the quadkeys are zoom 16 and in proper form
        Validates the price is accurate to current price of dutch auction
        Validates that the date is after the start time of the crowdsale
        @return true if the above conditions are met
    */
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

    /*
      Calculates given the current supply of LRG, how much to distribute to token purchaser
    */
    function numGoldToDistribute() 
        public
        view
        returns (uint256)
    {
        uint256 supply = nftContract_.totalSupply();
        if (supply < 20000) {
            return (2000);
        } else if (supply < 40000) {
            return (1400);
        } else if (supply < 60000) {
            return (900);
        } else if (supply < 80000) {
            return (500);
        }
        return (200);
    }

    /*
        Calls to super buy tokens which calculates correct value, then distributes gold
        Because LRG has 18 decimals, use ether helper to convert to correct distribution
        @param _tokenIds the ids of the tokens to be purchased
        @param _beneficiary recipient of the tokens
    */
    function buyTokens(
        uint256[] _tokenIds,
        address _beneficiary
    ) 
        public 
        payable 
    {
        super.buyTokens(_tokenIds, _beneficiary);

        // transfer Gold Reward to beneficiary
        goldContract_.transferFrom(owner, _beneficiary, _tokenIds.length.mul(10**goldContract_.decimals()).mul(numGoldToDistribute()));
    }

    /*
        Calculates dutch auction price from start of presale to now
        @param _tokenIds the ids of the tokens to be purchased
    */
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