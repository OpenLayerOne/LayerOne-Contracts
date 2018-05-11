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
        Given the quadkey, will return the parent quadkey n levels zoomed out
    */
    function quadkeyZoomOut(uint256 _quadKey, uint8 _n) 
        public pure
        returns (uint256)
    {
        uint64 quadKey = uint64(extractNBits(_quadKey, 64, 0));
        uint8 zoomlevel = uint8(quadKey & ZOOM_MASK);
        uint8 newZoom = zoomlevel - _n;
        uint256 zoomedQuadKey = extractNBits(_quadKey, newZoom*2, 64-newZoom*2);
        return (zoomedQuadKey * uint256(2) ** (64-newZoom*2)) | newZoom;
    }

    /*
        Lets you pack and arrange a uint256 with individual uint64s
    */
    function packBits(uint64 _a, uint64 _b, uint64 _c, uint64 _d) 
        public pure
        returns (uint256)
    {
        uint256 d = _d * uint256(2) ** 192;
        uint256 c = _c * uint256(2) ** 128;
        uint256 b = _b * uint256(2) ** 64;
        return uint256(_a) | b | c | d;
    }

    /*
        Lets you extract n bits starting at any point in a uint256
    */
    function extractNBits(
        uint256 bigNum, 
        uint8 n,
        uint8 starting
    )
        public pure
        returns (uint256) 
    {
        uint256 leftShift = bigNum * (uint256(2) ** uint256(256-n-starting));
        uint256 rightShift = leftShift / (uint256(2) ** uint256(256-n));
        return rightShift;
    }

    /*
        Will create mask to be used check if quadkey match zoom of a given level
        @param _n the zoom level to generate mask for
    */
    function createZoomMask(
        uint64 _n
    )         
        public pure  
        returns (uint64) 
    {
        require(_n <= MAX_ZOOM);
        uint64 numShifts = 64 - (_n*2);
        uint64 shifted = uint64(-1) * uint64(2) ** numShifts;
        return shifted;
    }

    /*
        Will validate a given quadkey has valid zoom
        @param _quadKey - quadkey to check
    */
    function isValidQuadkey(
        uint256 _quadKey
    ) 
        public pure 
        returns (bool) 
    {
        uint64 quadKey = uint64(extractNBits(_quadKey, 64, 0));
        uint256 zoom = (quadKey & ZOOM_MASK);
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
        public pure
        returns (bool) 
    {
        uint64 quadKey = uint64(extractNBits(_quadKey, 64, 0));
        return (quadKey & ZOOM_MASK) == _zoom;
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
        public pure
        returns (bool) 
    {
        uint64 parent = uint64(extractNBits(_parentId, 64, 0));
        uint64 child = uint64(extractNBits(_childId, 64, 0));
        uint64 mask = createZoomMask(parent & ZOOM_MASK);
        return ((child & mask) == (parent & mask));
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
        public pure 
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
