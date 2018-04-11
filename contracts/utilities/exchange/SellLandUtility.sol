pragma solidity >=0.4.18;

import "../LandContractUtility.sol";

/*
    @title Selling Land for Eth On LayerOne
    @author LayerOne
    @dev Contract that will allow users to sell NFT land tokens
*/
contract SellLandUtility is LandContractUtility {
    
    // Represents an auction on an NFT
    struct LandSale {
        // Current owner of NFT
        address seller;

        // Assigned for direct sale
        address buyer;
        
        // Price (in wei)
        uint256 salePrice;
        
        // Duration (in seconds) of sale before expires
        uint64 duration;
        // Time when listed
        // NOTE: 0 if this sale is concluded
        uint64 startedAt;
        
        // list of token ids in land sale
        uint64[] tokenIds;
    }

    event SaleSuccessful(uint256 parcelId, uint256 salePrice, address seller, address buyer);
    event SaleCreated(uint256 parcelId, uint256 salePrice, uint64 startedAt, uint64 duration, uint64[] tokenIds, address seller, address buyer);
    event SaleCancelled(uint256 parcelId, address seller);

    mapping (uint256 => LandSale) _parcelIdToSale;
   
    /* 
        @dev Constructs the SellLand with land contract
        @param _landContract - address of the nft contract holding the nfts
    */
    function SellLandUtility(
        address _landContract
    ) 
        public 
        LandContractUtility(_landContract)
    { }   

    /* 
        @dev Places a parcel for sale 
        @notice Seller must first approve this contract to sell the parcel
        @param _tokenIds - tile tokens
        @param _price - Price of item (in wei)
        @param _buyer Optional - include to restrict the purchase to someone
        @param _duration Optional - How long to keep the item listed
    */
    function placeForSale(
        uint64[] _tokenIds,
        uint256 _price,
        address _buyer,
        uint64 _duration
    ) 
        external 
        limitBatchSize(_tokenIds)
        whenNotPaused
        returns (uint) 
    {
        require(_price >= _minSalePrice);

        require(landContract.ownsTokens(msg.sender, _tokenIds));

        uint parcelId = landContract.uniqueTokenGroupId(_tokenIds);

        LandSale memory sale = LandSale(
            address(msg.sender),
            _buyer, // optional, enforced if present on payment
            uint256(_price),
            uint64(_duration),
            uint64(now),
            _tokenIds
        );

        _parcelIdToSale[parcelId] = sale;

        SaleCreated(
            parcelId,
            _price,
            sale.startedAt,
            _duration,
            _tokenIds,
            msg.sender,
            _buyer
        );

        return parcelId;
    }

    /*
        @dev Payment accepted for parcel, transfers parcel to the msg sender
        This contract must first be authorized for transfer either by private sale or 
        public sale escrow
        @param _tokenIds - tile tokens.
    */
    function payForParcel(
        uint64[] _tokenIds
    ) 
        whenNotPaused
        limitBatchSize(_tokenIds)
        public 
        payable 
    {
        uint _parcelId = landContract.uniqueTokenGroupId(_tokenIds);

        LandSale storage sale = _parcelIdToSale[_parcelId];
        if (sale.duration != 0) {
            require(now < sale.startedAt + sale.duration);
        }
        
        require(sale.salePrice == msg.value); // the asking price is paid
        require(sale.buyer == 0x0 || sale.buyer == msg.sender);

        landContract.transferFromMany(sale.seller, msg.sender, _tokenIds);

        uint256 payment = msg.value;
        uint256 fee = payment/_listingFee;
        require(sale.seller.send(payment - fee));

        SaleSuccessful(_parcelId, sale.salePrice, sale.seller, msg.sender);
        // Don't clear until event emitted
        _clearForSale(_parcelId);
    }
 
    /* 
        @dev Clears the storage for sale of a given parcel id
        @param _parcelId the parcel to wipe
        @param _tokenIds the tokenIds that are unlisted
    */
    function _clearForSale(
        uint256 _parcelId
    ) 
        internal 
    {
        delete _parcelIdToSale[_parcelId];
    }

    /*
        @dev Cancels a sale, seller is only one who can cancel
        @param _tokenIds - tile tokens.
    */
    function cancelForSale(
        uint64[] _tokenIds
    ) 
        limitBatchSize(_tokenIds)
        whenNotPaused
        public 
    {
        require(landContract.ownsTokens(msg.sender, _tokenIds));
        uint parcelId = landContract.uniqueTokenGroupId(_tokenIds);

        _clearForSale(parcelId);
        SaleCancelled(parcelId, msg.sender);
    }
}