pragma solidity ^0.4.19;

/* 
    @dev This library helps you deal with quadkeys on the blockchain
    allows you to create, verify, and work with quadkeys up to storage in uint64
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
        uint64 _n
    )         
        public 
        pure  
        returns (uint64) 
    {
        require(_n <= MAX_ZOOM);
        uint64 numShifts = 64 - (_n*2);
        uint64 shifted = 0xffffffffffffffff * uint64(2) ** numShifts;
        return shifted;
    }

    /*
        Will validate a given quadkey has valid zoom and the bits for that zoom are valid
        @param _quadKey - quadkey to check
    */
    function isValidQuadkey(
        uint64 _quadKey
    ) 
        public 
        pure 
        returns (bool) 
    {
        uint64 zoom = (_quadKey & ZOOM_MASK);
        if (zoom <= MAX_ZOOM) {
            for (uint64 i = 0; i < zoom; i++) {
                uint64 location = 64 - i * 2;
                bytes1 char_code = bytes1(_quadKey & (0x3 << location) >> location);
                if (char_code > 3) {
                    return false;
                }
                return true;
            }
        }
        return false;
    }

    /*
        Checks if the given quadkey has the given zoom
        @param _n the quadkey (uint64)
        @param _zoom the zoom level
    */
    function isZoom(
        uint64 _quadKey,
        uint64 _zoom
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
        uint64 _childId, 
        uint64 _parentId
    ) 
        public 
        pure
        returns (bool) 
    {
        uint64 parentZoom = _parentId & ZOOM_MASK;
        uint64 mask = createZoomMask(parentZoom);
        return ((_childId & mask) == (_parentId & mask));
    }

    /*
        Tests quadkey tokens are within parentId
        @param _tokenIds the tokenIds to test
        @param _parentId the id of the parent to check
    */
    function areChildrenWithinParent(
            uint64[] _tokenIds,                        
            uint64 _parentId
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
