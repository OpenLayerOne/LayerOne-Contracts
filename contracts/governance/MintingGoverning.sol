pragma solidity ^0.4.18;
import "./BatchSizeGoverning.sol";

contract MintingGoverning is BatchSizeGoverning {
    mapping (address => bool) public _approvedMinters;
    bool public _mintingOn = false;

    /* 
        @dev Will add a contract or address that can call minting function on 
        token contract
        @param _authorized address of minter to add
        @param _isAuthorized set authorized or not
    */
    function setApprovedMinter(
        address _authorized,
        bool _isAuthorized
    )
        external
        onlyOwner
    {
        _approvedMinters[_authorized] = _isAuthorized;
    }

    /* 
        Only minter contracts can access via this modifier
        Also, a minter either owns this contract or is in authorized list
    */
    modifier approvedMinter()
    {
        bool isAuthorized = _approvedMinters[msg.sender];
        require(isAuthorized || msg.sender == owner);
        _;
    }

    modifier isMintingOn()
    {
        require(_mintingOn);
        _;
    }
    
    /*
        @dev Allows owner of this contract to turn on/off public minting 
        @param _on true or false
    */
    function setMintingOn(
        bool _on
    )  
        external
        onlyOwner
    {
        _mintingOn = _on;
    }
}