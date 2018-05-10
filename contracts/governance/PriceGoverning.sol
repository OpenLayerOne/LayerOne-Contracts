
pragma solidity ^0.4.21;
import "./BatchSizeGoverning.sol";

contract PriceGoverning is BatchSizeGoverning  {
    uint256 internal _minSalePrice = 1 finney; // 0.001 Eth
    uint256 internal _listingFee = 28; // 3.57% for fee equiv to: 1/28

    /*
        @dev Allows owner of this contract to change a minimum sale price for auctions/sales 
        @param _price new minumum price
    */
    function setMinSalePrice(
        uint _price
    )  
        external
        onlyOwner
    {
        _minSalePrice = _price;
    }

    /*
        @dev Allows owner of this contract to change a minimum sale price for auctions/sales 
        @param _price new minumum price
    */
    function setListingFeeDivisor(
        uint _listingDivisor
    )  
        external
        onlyOwner
    {
        _listingFee = _listingDivisor;
    }
}
