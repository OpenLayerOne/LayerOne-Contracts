pragma solidity >=0.4.18;

import "../exchange/EnglishAuction.sol";

contract MintingAuctionUtility is EnglishAuction {
      /* 
        @dev When a terraform auction is won, this can redeem it, sends Created Event
        Sender must be approved
        @param _tokenIds - tile tokens.
     */
    function redeemTerraformAuction(
        uint256[] _tokenIds
    )
        external
        whenNotPaused
    {
        // will not complete if msg.sender did not win
        landContract.mint(msg.sender, _tokenIds);
        completeAuction(_tokenIds);
    }

    /* 
        @dev Creates and begins a new terraform auction (land is to be minted).
        @param _tokenIds - tile tokens.
        @param _startingPrice - Price of item (in wei) at beginning of auction.
        @param _duration - Length of time to move between starting
        @param _buyItNowPrice - Price user could buy it now at if set
     */
    function createTerraformAuction(
        uint256[] _tokenIds,
        uint256 _startingPrice,
        uint256 _duration,   
        uint256 _buyItNowPrice
    ) 
        limitBatchSize(_tokenIds)
        external
        onlyOwner
        whenNotPaused
        returns (uint) 
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_duration == uint256(uint64(_duration)));
        require(landContract.ownsTokens(0, _tokenIds));

        // build token ids for parcels
        return addAuction(this, _tokenIds, _startingPrice, _duration, _buyItNowPrice);
    }    

}