pragma solidity >=0.4.18;

import "../tokens/LayerOneLand.sol";

// mock class using BasicToken
contract LayerOneLandMock is LayerOneLand {
  function LayerOneLandMock(  
      uint64[] _tokenIds,
      address owner
    ) 
    public 
    LayerOneLand()
  {
    mint(owner, _tokenIds);
  }
}
