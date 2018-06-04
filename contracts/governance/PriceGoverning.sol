
pragma solidity ^0.4.21;
import "./BatchSizeGoverning.sol";
import "../libraries/QuadkeyLib.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract PriceGoverning is BatchSizeGoverning  {
    using SafeMath for uint256;

    uint256 internal _minSalePrice = 1 finney; // 0.001 Eth
    uint256 internal _listingFee = 20; // 5% for fee equiv to: 1/20

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

    struct Region {
        uint256 price;
        uint256 quantity;
    }

    // Mapping from quadtoken to latest market price
    mapping (uint256 => Region) regionSaleInfo;

    function recordSale(uint256 _tokenId, uint256 _price) 
        internal 
    {
        for (uint8 i = 0; i < 7; i++) {
            uint256 regionId = QuadkeyLib.zoomOut(_tokenId, uint8(16 - i));
            Region memory region = regionSaleInfo[regionId];
            uint256 newQuantity = region.quantity.add(1);
            uint256 newPrice = (region.price.mul(region.quantity) + _price).div(newQuantity);
            regionSaleInfo[regionId] = Region(newPrice, newQuantity);
        }
    }
    
    function estimatePrice(uint256 _tokenId, uint8 _minSales) 
        public view
        returns (uint256) 
    {
        for (uint8 i = 1; i < 7; i++) {
            uint256 regionId = QuadkeyLib.zoomOut(_tokenId, uint8(16 - i));
            Region memory region = regionSaleInfo[regionId];
            if (region.quantity > _minSales) {
                return region.price;
            }
        }
        return _minSalePrice;
    }
}
