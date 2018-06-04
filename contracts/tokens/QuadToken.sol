pragma solidity ^0.4.21;

import "./Batchable721Token.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../libraries/QuadkeyLib.sol";
import "./LRGToken.sol";

contract QuadToken is Batchable721Token {
  using SafeMath for uint256;


  event MetadataUpdated(uint256 indexed protocol, uint256 indexed tokenId, address indexed owner, string metadata);

  struct MetadataProtocol {
    uint256 rewardCreate;
    uint256 rewardUpdate;
    address wallet; // must approve this contract to do transferFrom
    address owner;
    address erc20Address;
    mapping (uint256 => string) tokenMetadata;
  }

  mapping (uint256 => MetadataProtocol) public metadataProtocols;

  function QuadToken() 
    public 
    ERC721Token("QuadToken", "QUAD")
  {
  }

  /*
    @dev Allows free public minting of zoom level 16 tokens
    @param _beneficiary - Who gets the token
    @param _tokenIds - tile tokens.
  */
  function publicMinting(
      address _beneficiary,
      uint256[] _tokenIds
  )
    limitBatchSize(_tokenIds)
    whenNotPaused
    isMintingOn
    public
  {
      for (uint i = 0; i < _tokenIds.length; i++) {
        require(QuadkeyLib.isZoom(_tokenIds[i], 16));
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
      uint256 _protocol,
      uint256[] _tokenIds,
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
    @dev Creates a metadata protocol.  For 3rd party protocol devs to control 
    their metadata associated with layer one quadtiles
    @param _protocol - the protocol of the data
    @param _rewardCreate - Reward for inserting new metadata
    @param _rewardUpdate - Reward for updating metadata
    @param _wallet - Source of the erc20 token funding
    @param _owner - who should own this protocol
    @param _erc20Token - the address of the token contract to handle transfer
  */
  function createMetadataProtocol(
    uint256 _protocol,
    uint256 _rewardCreate,
    uint256 _rewardUpdate,
    address _wallet,
    address _owner,
    address _erc20Token
  ) 
    public
  {
    require(msg.sender != 0);
    MetadataProtocol memory oldProtocol = metadataProtocols[_protocol];
    require (oldProtocol.owner == 0);

    MetadataProtocol memory protocol = MetadataProtocol(
      _rewardCreate,
      _rewardUpdate,
      _wallet,
      _owner,
      _erc20Token
    );

    metadataProtocols[_protocol] = protocol;
  }

  function updateReward( 
      uint256 _protocol,
      uint256 _rewardCreate,
      uint256 _rewardUpdate,
      address _wallet,
      address _owner,
      address _erc20Token
    )
      public 
    {
      MetadataProtocol storage oldProtocol = metadataProtocols[_protocol];
      require (oldProtocol.owner == msg.sender);
      oldProtocol.rewardCreate = _rewardCreate;
      oldProtocol.rewardUpdate = _rewardUpdate;
      oldProtocol.wallet = _wallet;
      oldProtocol.owner = _owner;
      oldProtocol.erc20Address = _erc20Token;
    }

  /*
    @dev Updates tile's metadata for a given protocol.  
    This will payout any rewards associated with the protocol
    Both the protocol owner and the tile owner has access to this data
    @param _protocol - the protocol of the data
    @param _tokenId - the id of the token
    @param _metadata - the string metadata associated with tile
  */
  function updateTokenMetadata(
    uint256 _protocol,
    uint256 _tokenId, 
    string _metadata
  ) 
    whenNotPaused
    public 
  {
    require(QuadkeyLib.isValidQuadkey(_tokenId));
    bool isOwner = msg.sender == ownerOf(_tokenId);
    MetadataProtocol storage protocol = metadataProtocols[_protocol];
    bool isProtocolOwner = protocol.owner == msg.sender;
    ERC20 erc20Address = ERC20(protocol.erc20Address);

    require(isOwner || isProtocolOwner);
    bytes memory tempEmptyStringTest = bytes(protocol.tokenMetadata[_tokenId]);
    protocol.tokenMetadata[_tokenId] = _metadata;

    if (tempEmptyStringTest.length == 0) {
        // This is a new addition
        if (protocol.rewardCreate > 0) {
          erc20Address.transferFrom(protocol.wallet, msg.sender, protocol.rewardCreate);
        }
    } else {
        // This is an update
        if (protocol.rewardUpdate > 0) {
          erc20Address.transferFrom(protocol.wallet, msg.sender, protocol.rewardUpdate);
        }
    }
    emit MetadataUpdated(_protocol, _tokenId, msg.sender, _metadata);
  }

  /*
    @dev For a given token, and protocol grab metadata
    @param _protocol - the protocol of the data
    @param _tokenId - the id of the token
  */
  function getTokenMetadata(    
    uint256 _protocol,
    uint256 _tokenId
  ) 
    public
    view
    returns (string)
  {
    MetadataProtocol storage protocol = metadataProtocols[_protocol];
    return protocol.tokenMetadata[_tokenId];
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
