pragma solidity ^0.4.18;

import "./Crowdsale721.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../libraries/QuadkeyLib.sol";
import "../libraries/DutchAuctionLib.sol";

contract Capped721DutchCrowdsale is Crowdsale721 {

    using SafeMath for uint256;
    
    // Number of remaining whitelisted user slots
    uint32 public minTilesSold = 100000;

    uint256 public endPrice;

    // Hard cap for the land sale
    uint256 public cap;

    /*
        The crowdsale for Layer One 
        @param _cap Has a cap, so that it ends when cap reached
        @param _landsaleStart when the first public purchase period should begin
        all dates will be relative this beginning.
        @param _landsaleEnd when all crowdsale functionality is over
        @param _wallet the destination of purchase funds
        @param _nftContract The contract that holds the tile ownership information
    */
    function Capped721DutchCrowdsale(
        uint32 _minTilesSold,
        uint256 _cap,
        uint256 _landsaleStart,
        uint256 _landsaleEnd,
        uint256 _startPrice,
        uint256 _endPrice,
        address _wallet,
        address _nftContract
    ) 
        Crowdsale721(_landsaleStart, _landsaleEnd, _startPrice, _wallet, _nftContract)
        public 
    {
        require(_cap > 0);
        
        cap = _cap;
        minTilesSold = _minTilesSold;
        endPrice = _endPrice;
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return (weiRaised >= cap || nftContract_.totalSupply() >= minTilesSold );
    }

    function validPurchase(uint64[] _tokenIds) 
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

    // calculates dutch auction price from start of presale to now
    function price(uint64[] _tokenIds) 
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