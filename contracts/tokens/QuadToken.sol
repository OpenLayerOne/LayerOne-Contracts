pragma solidity ^0.4.18;

import "./Batchable721Token.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../libraries/QuadkeyLib.sol";

contract QuadToken is Batchable721Token {
  using SafeMath for uint256;

  // Contracts or people that own data protocols on the 
  mapping(uint32 => address) internal protocolOwners;
  mapping (uint64 => mapping (uint32 => string)) internal protocolTokenMetadata;

  event MetadataUpdated(uint32 indexed protocol, uint64 indexed tokenId, address indexed owner);

  function QuadToken() 
    public 
    ERC721Token("QuadToken", "QUAD")
  {
  }

  modifier validateQuadKeys(uint64[] _quadKeys)
  {
      for (uint i = 0; i < _quadKeys.length; i++) {
          require(QuadkeyLib.isValidQuadkey(_quadKeys[i]));
      }
      _;
  }

  function publicMinting(
      address _beneficiary,
      uint64[] _tokenIds
  )
    validateQuadKeys(_tokenIds)
    limitBatchSize(_tokenIds)
    whenNotPaused
    isMintingOn
    public
  {
      for (uint i = 0; i < _tokenIds.length; i++) {
        require(QuadkeyLib.isValidQuadkey(_tokenIds[i]));
        // This will assign ownership, and also emit the Transfer event
        _mint(_beneficiary, _tokenIds[i]); 
      }
  }

  /*
    @dev Updates many tiles for metadata at the same time
    @param _tokenIds - tile tokens.
    @param _metadata - the string metadata associated with tile
  */
  function updateManyTokenMetadata(
      uint32 _protocol,
      uint64[] _tokenIds,
      string _metadata
  ) 
      limitBatchSize(_tokenIds) 
      public 
  {
    for (uint i = 0; i < _tokenIds.length; i++) {
      updateTokenMetadata(_protocol, _tokenIds[i], _metadata);
    }
  }

  /*
    @dev Sets owner of a protocol.  For 3rd party protocol devs to control 
    their metadata associated with layer one quadtiles
    @param _protocol - the protocol of the data
    @param _owner - who should own this protocol
  */
  function setProtocolOwner(
    uint32 _protocol,
    address _owner
  ) 
    onlyOwner
    public
  {
    protocolOwners[_protocol] = _owner;
  }

  /*
    @dev Updates tile's metadata for a given protocol.  
    Both the protocol owner and the tile owner has access to this data
    @param _protocol - the protocol of the data
    @param _tokenId - the id of the token
    @param _metadata - the string metadata associated with tile
  */
  function updateTokenMetadata(
    uint32 _protocol,
    uint64 _tokenId, 
    string _metadata
  ) 
    whenNotPaused
    public 
  {
    require(QuadkeyLib.isValidQuadkey(_tokenId));
    bool isOwner = msg.sender == ownerOf(_tokenId);
    bool isProtocolOwner = msg.sender == protocolOwners[_protocol];
    require(isOwner || isProtocolOwner);
    protocolTokenMetadata[_tokenId][_protocol] = _metadata;
    emit MetadataUpdated(_protocol, _tokenId, msg.sender);
  }

  /*
    @dev For a given token, and protocol grab metadata
    @param _protocol - the protocol of the data
    @param _tokenId - the id of the token
  */
  function getTokenMetadata(    
    uint32 _protocol,
    uint64 _tokenId
  ) 
    public
    view
    returns (string)
  {
    return protocolTokenMetadata[_tokenId][_protocol];
  }

  bytes4 constant public InterfaceSignature_ERC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256('supportsInterface(bytes4)'));
    */

  bytes4 constant public InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    /*
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
    bytes4(keccak256('tokenByIndex(uint256)'));
    */

  bytes4 constant public InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('tokenURI(uint256)'));
    */

  bytes4 constant public InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('getApproved(uint256)')) ^
    bytes4(keccak256('setApprovalForAll(address,bool)')) ^
    bytes4(keccak256('isApprovedForAll(address,address)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'));
    */

  // bytes4 public constant InterfaceSignature_ERC721Optional = 0x4f558e79;
    /*
    bytes4(keccak256('exists(uint256)'));
    */

  /**
   * @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
   * @dev Returns true for any standardized interfaces implemented by this contract.
   * @param _interfaceID bytes4 the interface to check for
   * @return true for any standardized interfaces implemented by this contract.
   */
  function supportsInterface(bytes4 _interfaceID)
    external 
    view 
    returns (bool)
  {
    return ((_interfaceID == InterfaceSignature_ERC165)
      || (_interfaceID == InterfaceSignature_ERC721)
      || (_interfaceID == InterfaceSignature_ERC721Enumerable)
      || (_interfaceID == InterfaceSignature_ERC721Metadata));
  }
  
}
