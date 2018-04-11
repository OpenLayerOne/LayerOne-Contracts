pragma solidity >=0.4.18;

import "../LandContractUtility.sol";

/*
    @title Trading Land for Land On LayerOne
    @author LayerOne
    @dev Contract that will allow users to trade land for land
*/
contract TradeLand is LandContractUtility {

    struct Trade {
        // Current owner of NFT
        address seller;

        // Assigned for direct sale
        address buyer;

        // Optional additional funds offered (not necessary)
        uint256 additionalFunds;
        
        // Duration (in seconds) of offer before expires
        uint64 duration;

        // Time when listed
        // NOTE: 0 if this sale is concluded
        uint64 startedAt;
        
        // list of token ids offered
        uint256[] offeredTokens;

        // list of token ids requested
        uint256[] forTokens;
    }

    function offer(
        uint64[] _offerTokens,
        uint64[] _forTokens, 
        address _buyer,  
        uint64 duration      
    )
        external
    {
        require(landContract.ownsTokens(msg.sender, _offerTokens));
    }

    /* 
        @dev Constructs the TradeLand with references to contracts
        @param _landContract - address of the nft contract holding the nft
    */
    function TradeLand(
        address _landContract
    ) 
        public 
        LandContractUtility(_landContract)
    { } 

    function accept(

    )
        payable
        external
    {

    }

    function counterOffer(

    )
        external
    {

    }

}