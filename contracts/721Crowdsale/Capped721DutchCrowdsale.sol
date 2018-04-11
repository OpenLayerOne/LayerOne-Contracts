pragma solidity ^0.4.18;

import "./Crowdsale721.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../libraries/QuadkeyLib.sol";
import "../libraries/DutchAuctionLib.sol";

contract Capped721DutchCrowdsale is Crowdsale721 {

    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;

    event PresaleSpotReserved(address indexed user, uint32 presaleSpotsTaken);

    /* 
        A certain amount of whitelisted users can be added per city to be
        allowed to purchase land earlier than the general public.
    */
    mapping (address => uint32) public _whitelistedUsers;

    // Number of remaining whitelisted user slots
    uint32 public presaleSpotsRemaining = 400;
    uint32 public presaleSpotsTaken = 0;

    uint256 public presaleStart;
    uint256 public presaleEnd;

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
        uint256 _cap,
        uint256 _presaleStart,
        uint256 _presaleEnd,
        uint256 _landsaleStart,
        uint256 _landsaleEnd,
        uint256 _startPrice,
        uint256 _endPrice,
        address _wallet,
        address _nftContract, 
        uint32 _presaleSpots
    ) 
        Crowdsale721(_landsaleStart, _landsaleEnd, _startPrice, _wallet, _nftContract)
        public 
    {
        require(_cap > 0);
        cap = _cap;
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
        presaleSpotsRemaining = _presaleSpots;
        endPrice = _endPrice;
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= cap;
        return capReached || super.hasEnded();
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
        
        if (isPresaleActive()) {
            //ensure sender is whitelisted
            return (_whitelistedUsers[msg.sender] > 0);
        }

        return super.validPurchase(_tokenIds);
    }

    // overriding Crowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function isPresaleActive() 
        public 
        view 
        returns (bool) 
    {
        return (now < presaleEnd && now >= presaleStart);
    }

    function reservePresaleSpot()
        public
    {
        require(now < presaleStart);
        require(presaleSpotsRemaining > 0);
        if (_whitelistedUsers[msg.sender] == 0) {
            presaleSpotsRemaining = uint32(presaleSpotsRemaining.sub(1));
            _whitelistedUsers[msg.sender] = presaleSpotsRemaining;
            presaleSpotsTaken = uint32(presaleSpotsTaken.add(1));
            emit PresaleSpotReserved(msg.sender, presaleSpotsTaken);
        }
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