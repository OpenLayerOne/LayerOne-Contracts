pragma solidity ^0.4.19;

/* 
    @dev This library helps you deal with quadkeys on the blockchain
    allows you to create, verify, and work with quadkeys up to storage in uint256
    @author LayerOne
*/
library QuadkeyLib {
    
    // This masks the last 5 bits of the quadkey which is where the zoom storage is
    uint8 constant ZOOM_MASK = 31;
    
    // 29 is the max zoom allowed in quadkey mapping
    uint8 constant MAX_ZOOM = 29;

    /*
        Will create mask to be used check if quadkey match zoom of a given level
        @param _n the zoom level to generate mask for
    */
    function createZoomMask(
        uint256 _n
    )         
        public 
        pure  
        returns (uint256) 
    {
        require(_n <= MAX_ZOOM);
        uint256 numShifts = 64 - (_n*2);
        uint256 shifted = 0xffffffffffffffff * uint256(2) ** numShifts;
        return shifted;
    }

    /*
        Will validate a given quadkey has valid zoom
        @param _quadKey - quadkey to check
    */
    function isValidQuadkey(
        uint256 _quadKey
    ) 
        public 
        pure 
        returns (bool) 
    {
        uint256 zoom = (_quadKey & ZOOM_MASK);
        return (zoom <= MAX_ZOOM);
    }

    /*
        Checks if the given quadkey has the given zoom
        @param _n the quadkey (uint256)
        @param _zoom the zoom level
    */
    function isZoom(
        uint256 _quadKey,
        uint256 _zoom
    )         
        public 
        pure
        returns (bool) 
    {
        return (_quadKey & ZOOM_MASK) == _zoom;
    }

    /*
        Checks if the child quadkey lives within the parent
        @param _childId the child to test
        @param _parentId the parent id to test
    */
    function isChildWithinParent(
        uint256 _childId, 
        uint256 _parentId
    ) 
        public 
        pure
        returns (bool) 
    {
        uint256 parentZoom = _parentId & ZOOM_MASK;
        uint256 mask = createZoomMask(parentZoom);
        return ((_childId & mask) == (_parentId & mask));
    }

    /*
        Tests quadkey tokens are within parentId
        @param _tokenIds the tokenIds to test
        @param _parentId the id of the parent to check
    */
    function areChildrenWithinParent(
            uint256[] _tokenIds,                        
            uint256 _parentId
    )
        public
        pure 
        returns (bool) 
    {
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (isChildWithinParent(_tokenIds[i], _parentId) == false) {
                return false;
            }
        }
        return true;
    }
}
