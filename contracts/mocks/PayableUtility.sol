pragma solidity ^0.4.18;


import "../utilities/exchange/SellLandUtility.sol";


contract PayableUtility is SellLandUtility {

  function PayableUtility (

    address _nft
  ) 
    payable public
    SellLandUtility(_nft)
  {
  }

}
