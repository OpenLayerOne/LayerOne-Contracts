pragma solidity >=0.4.18;

// import 'openzeppelin-solidity/contracts/lifecycle/Pausable.sol';

/* @title Auction Core
    @dev Contains models, variables, and internal methods for the auction.
    @author LayerOne
    @notice We omit a fallback function to prevent accidental sends to this contract.
*/ 
contract AuctionBase {

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;

        // Current high bidder of NFT
        address highBidder;
        
        // Price (in wei)
        uint256 currentPrice;

        // price you can buy it now for
        uint256 buyItNowPrice;
        
        // Duration (in seconds) of auction
        uint64 duration;
        
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 createdAt;
        
        // list of token ids in auction
        uint256[] tokenIds;
    }

    // Map from auction ID to their corresponding auction.
    mapping (uint256 => Auction) _parcelIdToAuction;


    event AuctionSuccessful(uint256 parcelId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 parcelId);
    event AuctionCreated(uint256 parcelId, uint256 startingPrice, uint64 duration, uint64 createdAt, uint256[] tokenIds);

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _parcelId) internal {
        _removeAuction(_parcelId);
        // todo, transferring of funds, etc
        emit AuctionCancelled(_parcelId);
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _parcelId - ID of auction.
    function _removeAuction(uint256 _parcelId) internal {
        delete _parcelIdToAuction[_parcelId];
    }

    /*
        @dev Returns true if the auction is running.
        An auction is running if the buy it now price has not been met, or the duration has not lapsed
        @param _auction - Auction to check.
    */
    function _isOnAuction(
        Auction storage _auction
    ) 
        internal 
        view 
        returns (bool) 
    {
        uint64 curTime = uint64(now);
        if (_auction.buyItNowPrice > 0 && _auction.buyItNowPrice <= _auction.currentPrice) {
            // buy it now price met, auction is off
            return false;
        }
        return (_auction.createdAt <= curTime && curTime < _auction.createdAt + _auction.duration);
    }
    
    // @dev Returns the current price of the auction
    /// @param _parcelId - Auction to check price of
    function currentPrice(uint _parcelId) public view returns (uint256) {
        return _parcelIdToAuction[_parcelId].currentPrice;
    }
    
    // @dev Returns the current price of the auction
    /// @param _parcelId - Auction to check price of
    function highBidder(uint _parcelId) public view returns (address) {
        return _parcelIdToAuction[_parcelId].highBidder;
    }
    
}
