pragma solidity >=0.4.18;

import "./AuctionBase.sol";
import "../LandContractUtility.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";

// import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

/*
    @title English NFT Auction (like eBay auction)
    @author LayerOne
    @dev Contract that will auction off NFT Land Token 
    This is a utility contract that someone can use to auction their token off
*/
contract EnglishAuction is AuctionBase, LandContractUtility {
    event Debug(address owner);
    event BidSuccessful(uint256 parcelId, uint256 price, bool buyItNow);

     /* 
        @dev Constructs the EnglishAuction with references to contracts
        @param _landContract - address of the nft contract holding the nft
     */
    function EnglishAuction(
        address _landContract
    ) 
        public 
        LandContractUtility(_landContract)
    { 
    } 

    /* 
        @dev Creates and begins a new user auction.
        @param _tokenIds - tile tokens.
        @param _startingPrice - Price of item (in wei) at beginning of auction.
        @param _duration - Length of time to move between starting
        @param _buyItNowPrice - Price user could buy it now at if set
    */
    function createAuction(
        uint64[] _tokenIds,
        uint256 _startingPrice,
        uint256 _duration,
        uint256 _buyItNowPrice
    )
        external
        limitBatchSize(_tokenIds)
        whenNotPaused
        returns (uint)
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the auction struct.
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_duration == uint256(uint64(_duration)));

        // check token ids are owned by message sender
        require(landContract.ownsTokens(msg.sender, _tokenIds));

        return addAuction(msg.sender, _tokenIds, _startingPrice, _duration, _buyItNowPrice);
    }    
 
     /* 
        @dev Adds an auction to the list of open auctions.
        @param _seller - Who is selling the auction
        @param _tokenIds - list of token ids to add
        @param _startingPrice - Price of item (in wei) at beginning of auction.
        @param _duration - Length of time to move between starting
        @param _buyItNowPrice - Price user could buy it now at if set
     */
    function addAuction(
        address _seller, 
        uint64[] _tokenIds, 
        uint _startingPrice,
        uint _duration,
        uint _buyItNowPrice
    )  
        onlyOwner 
        public
        returns (uint) 
    {
        // Require that all auctions have a duration of > 10 min and less than 30 days
        require(_duration >= 10 minutes && _duration < 30 days);
        require(_startingPrice >= _minSalePrice);

        uint parcelId = landContract.uniqueTokenGroupId(_tokenIds);

        Auction memory auction = Auction(
            _seller,
            0, // no high bidder when created
            uint256(_startingPrice),
            uint256(_buyItNowPrice),
            uint64(_duration),
            uint64(now),
            _tokenIds
        );

        _parcelIdToAuction[parcelId] = auction;

        AuctionCreated(
            uint256(parcelId),
            uint256(auction.currentPrice),
            uint64(auction.duration),
            uint64(auction.createdAt),
            _tokenIds
        );
        return parcelId;
    }

     /* 
        @dev Returns auction data in an array for outside access
        @param _parcelId - id of the requested auction
     */
    function getAuction(
        uint _parcelId
    ) 
        public
        constant 
        returns(address, address, uint, uint, uint, uint, uint64[]) 
    {
        Auction storage auction = _parcelIdToAuction[_parcelId];
        return (auction.seller, auction.highBidder, auction.currentPrice, auction.duration, auction.createdAt, auction.buyItNowPrice, auction.tokenIds);
    }

    /*
        @dev Raises price for auction
        Does NOT transfer ownership of token.
        @param _parcelId The id of the auction to bid on
    */
    function bid (
        uint _parcelId
    )
        external
        payable
        whenNotPaused
    {
        // Get a reference to the auction struct
        Auction storage auction = _parcelIdToAuction[_parcelId];

        // bidding must happen on live auction
        require(_isOnAuction(auction));

        // Check that the bid is greater the current price
        require(msg.value > auction.currentPrice);

        address oldHighBidder = auction.highBidder; // capture the second place bidder

        // track open auction values to store winnings for sellers
        pendingSaleValue += msg.value;

        if (oldHighBidder != 0) {
            // send value the previous high bidder if this is an outbid
            require(oldHighBidder.send(auction.currentPrice));
            pendingSaleValue -= auction.currentPrice;
        }

        // set price and new high bidder
        auction.currentPrice = msg.value;
        auction.highBidder = msg.sender;

        emit BidSuccessful(_parcelId, msg.value, msg.value == auction.buyItNowPrice);
    }

    /*
        @dev The winning bidder is the high bidder when the auction is off
        @param _tokenIds the token ids to finish and unlist
        @notice the sender must be the high bidder
    */
    function completeAuction(        
        uint64[] _tokenIds
    ) 
        public
    {
        uint _parcelId = landContract.uniqueTokenGroupId(_tokenIds);
        Auction storage auction = _parcelIdToAuction[_parcelId];
        require(msg.sender == auction.highBidder || msg.sender == owner);
        require(auction.createdAt != 0); // this auction is not already concluded
        require(_isOnAuction(auction) == false); // auction is redeemable

        pendingSaleValue -= auction.currentPrice;
        emit AuctionSuccessful(_parcelId, auction.currentPrice, auction.highBidder);
    }

    /*
        @dev Redeems the auction with payment for seller based auction (not terraform auction)
        issues Transferred event for each token in auction on success
        may be called by seller or high bidder to redeem payment or token
        @param _parcelId the auction to redeem
        @notice the sender must be the high bidder
    */
    function redeem(
        uint256 _parcelId
    ) 
        external 
        whenNotPaused
        returns (uint256)
    {
        Auction storage auction = _parcelIdToAuction[_parcelId];
        // transfer token ids to winner from auction
        uint64[] memory tokenIds = auction.tokenIds;
        for (uint i=0; i<tokenIds.length; i++) {
            // this contract is msg.sender (and owner) so it can redeem to the high bidder on the contract
            // TODO safe transfer
            // landContract.transfer(auction.highBidder, tokenIds[i]);
        }
        // send money to auction seller minus the fee
        uint256 fee = auction.currentPrice/_listingFee;
        require(auction.seller.send(auction.currentPrice - fee));
        completeAuction(tokenIds);
        return _parcelId;
    }

    /*
        @dev can only be done if no bids have been placed on auction
        Can be cancelled by the seller or this auction contract as long as no bids
        have been placed.
        @param _parcelId the auction to redeem
    */
    function cancelAuction(
        uint256 _parcelId
    ) 
        external 
        whenNotPaused
    {
        Auction storage auction = _parcelIdToAuction[_parcelId];
        uint64[] memory tokenIds = auction.tokenIds;

        require(auction.highBidder == 0); // cannot cancel auction that has been bid on
        bool terraformAuction = landContract.ownsTokens(0, tokenIds);
        require(msg.sender == auction.seller || terraformAuction); // seller or auction can cancel

        if (!terraformAuction) {
            // if there was an original owner, transfer tokens back to seller
            for (uint i=0; i<tokenIds.length; i++) {
                // seller has authorized the auction to transfer
                // TODO safe transfer
                // landContract.transfer(auction.seller, tokenIds[i]);
            }
        }

        _cancelAuction(_parcelId);
    }        
}