pragma solidity >=0.4.18;

import "../tokens/QuadToken.sol";

// mock class using BasicToken
contract QuadTokenMock is QuadToken {
  function QuadTokenMock(  

      uint256[] _tokenIds,
      address _owner
    ) 
    public 
    QuadToken()
  {
    mint(_owner, _tokenIds);
  }
}
