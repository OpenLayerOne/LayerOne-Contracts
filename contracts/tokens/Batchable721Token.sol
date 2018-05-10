pragma solidity ^0.4.21;

import "../governance/MintingGoverning.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";

contract Batchable721Token is ERC721Token, MintingGoverning {

  /*
   @dev Establishes ownership and brings token into existence AKA minting a token 
   @param _beneficiary - who gets the the tokens
   @param _tokenIds - tokens.
  */
  function mint(
      address _beneficiary,
      uint256[] _tokenIds
  )
    approvedMinter
    whenNotPaused
    public
  {
      for (uint i = 0; i < _tokenIds.length; i++) {
        // This will assign ownership, and also emit the Transfer event
        _mint(_beneficiary, _tokenIds[i]); 
      }
  }

  /*
   @dev Removes ownership from tile effectively removing from existence
   This can only be called by an approved governing contract (DAU) 
   @param _beneficiary - who gets the the tokens
   @param _tokenIds - tokens.
  */
  function burn(
      address _owner,
      uint256[] _tokenIds
  )
    approvedMinter
    whenNotPaused
    public 
  {
      for (uint i = 0; i < _tokenIds.length; i++) {
        // This will remove ownership, and also emit the Transfer event
        _burn(_owner, _tokenIds[i]);
      }
  }

  /*
   @dev returns the first minumum id in tokenIds which can function as the auction id 
    you cannot have the same tile up for auction or for sale
   @param _tokenIds the list of tokenIds in group
  */
  function uniqueTokenGroupId (
    uint256[] memory _tokenIds
  ) 
    public 
    pure 
    returns (uint)
  {
      // require token ids are sorted ascending and no duplicates
      for (uint i = 1; i < _tokenIds.length; i++) {
        require(_tokenIds[i] > _tokenIds[i-1]);
      }
      return uint256(keccak256(_tokenIds));
  }


  /***** TRANSFERS *****/

  /*
    @dev Transfer multiple tokens at once
    @param _from - Who we are transferring from.
    @param _to - beneficiary of token.
    @param _tokenIds - tokens to transfer.
    @param sender - approved for transfer of tokens
  */
  function transferFromMany(
    address _from,
    address _to, 
    uint256[] _tokenIds
  ) 
    limitBatchSize(_tokenIds)
    whenNotPaused 
    public 
  {
      for (uint i = 0; i < _tokenIds.length; i++) {
          transferFrom(_from, _to, _tokenIds[i]);
      }
  }

  /***** APPROVALS *****/
  
  /*
    @dev Approves a list of tokens for transfer
    @param sender - must be owner of tokens
    @param _tokenIds - tokens to approve.
  */
  function approveMany(
    address _to,
    uint256[] _tokenIds
  ) 
    limitBatchSize(_tokenIds)
    whenNotPaused 
    public 
  {
      for (uint i = 0; i < _tokenIds.length; i++) {
          approve(_to, _tokenIds[i]);
      }
  }

  /*
    @dev Check if an owner owns all tokens
    @param _owner - possible owner of tokens
    @param _tokenIds - tokens to check ownership.
  */
  function ownsTokens(
    address _owner, 
    uint256[] _tokenIds
  ) 
    public 
    constant 
    limitBatchSize(_tokenIds)
    returns (bool) 
  {
    for (uint i = 0; i < _tokenIds.length; i++) {
      if (ownerOf(_tokenIds[i]) != _owner) {
        return false;
      }
    }
    return true;
  }

}
