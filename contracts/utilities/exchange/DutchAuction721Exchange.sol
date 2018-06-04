pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../libraries/QuadkeyLib.sol";
import "../../libraries/DutchAuctionLib.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../tokens/LRGToken.sol";
import "../../tokens/QuadToken.sol";
 

contract DutchAuction721Exchange {

    using SafeMath for uint256;
    
    // Number of remaining whitelisted user slots
    LRGToken public goldContract_;
    QuadToken public nftContract_;

    uint256 public endPrice;

    /*
        Peer to peer dutch auction exchange
    */
    function DutchAuctionExchange(
        address _nftContract,
        address _goldContract
    ) 
        public 
    {
        goldContract_ = LRGToken(_goldContract);
        nftContract_ = QuadToken(_nftContract);
    }
   
}