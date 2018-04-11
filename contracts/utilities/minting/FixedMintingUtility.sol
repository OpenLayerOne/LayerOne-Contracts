pragma solidity >=0.4.18;

import "../LandContractUtility.sol";


/*
    @title Has unique ability to mint land on layer one after ILO
*/
contract FixedMintingUtility is LandContractUtility {

    uint256 public fixedPrice = 50 finney;

    function FixedMintingUtility(
        address _landContract
    ) 
        public 
        LandContractUtility(_landContract)
    { 
    } 

     /* 
        @dev After crowdsale, allows us to continue to sell the remainder of land
        for a fixed price
        @param _tokenIds - tile tokens.
        @param _beneficiary - Who receives the land 
     */
    function fixedPricePurchase(
        uint64[] _tokenIds,
        address _beneficiary
    )
        external
        payable
        whenNotPaused
    {   
        require(msg.sender != 0x0);
        require(msg.value == fixedPrice);
        address beneficiary = _beneficiary == 0x0 ? msg.sender : _beneficiary;

        // This will issue a transferred event
        landContract.mint(beneficiary, _tokenIds);
        emit LandPurchase(msg.sender, beneficiary, msg.value);
    }

    function updateFixedPrice(
       uint256 _newPrice
    )
        public
        onlyOwner
    {
        fixedPrice = _newPrice;
    }

}