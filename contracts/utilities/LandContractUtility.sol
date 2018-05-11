pragma solidity >=0.4.18;

import "../tokens/QuadToken.sol";
import "../governance/PriceGoverning.sol";

contract LandContractUtility is PriceGoverning {
    QuadToken public landContract;
    uint256 public pendingSaleValue;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    */
    event LandPurchase(address indexed purchaser, address indexed beneficiary, uint256 value);
    event Withdraw(address utility, address beneficiary, uint value);
    /* 
        @dev Constructs the TradeLand with land contract
        @param _landContract - address of the nft contract holding the nfts
    */
    function LandContractUtility (
        address _landContract
    ) 
        public 
    {
        setNFTLandContract(_landContract);
    } 

    /* 
        @dev Sets the land contract and tests that it supports 721 interface
        @param _landContract - address of the nft contract
    */
    function setNFTLandContract(address _nftAddress) internal {
        QuadToken candidateContract = QuadToken(_nftAddress);
        // bytes4 ERC721 = candidateContract.InterfaceSignature_ERC721();
        // // require(candidateContract.supportsInterface(ERC721));
        landContract = candidateContract;
    }

    /*
        @dev Remove all Ether from the contract, minus any pending sale value to be calculated by contract
    */
    function withdrawBalance() 
        external 
        onlyOwner 
        returns (bool) 
    {
        if (address(this).balance > pendingSaleValue) {
            uint value = address(this).balance - pendingSaleValue;
            emit Withdraw(address(this), msg.sender, value);
            return (msg.sender.send(value));
        }    
        return false;
    }

    // TODO make right
    bytes4 constant InterfaceSignature_QuadTokenContract = 0x51123123;
    /*
    TODO:
    bytes4(keccak256('withdrawBalance()')) ^
    bytes4(keccak256('LandContractUtility(address)')) ^
    bytes4(keccak256('setNFTLandContract(address)'));
    */


    /*
        @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
        Returns true for any standardized interfaces implemented by this contract.
        @param _interfaceID : Checks if these bytes match the expected ERC721
    */
    function supportsInterface(
        bytes4 _interfaceID
    ) 
        public 
        view 
        returns (bool) 
    {
        // return true;
        return ((_interfaceID == landContract.InterfaceSignature_ERC165()) 
        || (_interfaceID == InterfaceSignature_QuadTokenContract));
    }

}

