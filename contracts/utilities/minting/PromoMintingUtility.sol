pragma solidity >=0.4.18;

import "../LandContractUtility.sol";

/*
    @title Has unique ability to mint land on layer one after ILO
*/
contract PromoMintingUtility is LandContractUtility {
    using SafeMath for uint;
    event PromoRedeemed(address purchaser, address to, uint64 tokenId);

    uint public outstandingPromoTokens;
    uint public redeemedPromoTokens;

    mapping (uint64 => uint64) private promoTokens;

    function PromoMintingUtility(
        address _landContract
    ) 
        public 
        LandContractUtility(_landContract)
    { 
    } 

     /* 
        @dev User can redeem promo to beneficiary 
        @param _tokenIds - tile tokens.
        @param _beneficiary - Who receives the land 
     */
    function redeemPromo(
        uint64 _promoId,
        address _beneficiary
    )
        external
        whenNotPaused
    {   
        require(msg.sender != 0x0);
        address beneficiary = _beneficiary == 0x0 ? msg.sender : _beneficiary;
        uint64 tokenId = promoTokens[_promoId];

        // check this is a valid loaded promo id
        require(tokenId != 0);
        
        uint64[] memory tokenIds = new uint64[](1);
        tokenIds[0] = tokenId;
        // This will issue a transferred event
        landContract.mint(beneficiary, tokenIds);
        delete promoTokens[_promoId];
        redeemedPromoTokens = redeemedPromoTokens.add(1);
        outstandingPromoTokens = outstandingPromoTokens.sub(1);
        emit PromoRedeemed(msg.sender, beneficiary, tokenId);
    }

    function token(uint64 _promoId) view public returns (uint64) {
        return promoTokens[_promoId];
    }

    function addPromoTokens(
        uint64[] _promoIds,
        uint64[] _tokenIds
    )
        public
        onlyOwner
    {        
        require(_promoIds.length <= 300); // should not be adding too many promo ids
        require(_promoIds.length == _tokenIds.length);
        for (uint i = 0; i < _promoIds.length; i++) {
            if (promoTokens[_promoIds[i]] == 0) {
                outstandingPromoTokens = outstandingPromoTokens.add(1);
            }
            promoTokens[_promoIds[i]] = _tokenIds[i];
        }
    }
}