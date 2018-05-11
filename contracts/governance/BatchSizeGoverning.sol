pragma solidity >=0.4.18;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract BatchSizeGoverning is Pausable {
    uint8 public batchSize = 64;

    function setBatchSize (
        uint8 _size
    )
        external
        onlyOwner
    {
        require(_size > 0);
        batchSize = _size;
    }

    /*
        @dev Validates the length of list is not over block limit estimation 
        @param _ids - uint256 to check.
    */
    modifier limitBatchSize(
        uint256[] _ids
    ) {
        require(_ids.length <= batchSize);
        _;
    }
}

