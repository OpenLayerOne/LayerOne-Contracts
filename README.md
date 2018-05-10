# LayerOne-Contracts Contents
This public, open source repository contains the following:
* LayerOne Smart Contracts
* QuadToken contract for allocating Quadkey ownership (LayerOne's proof of concept is the LandRush game)
* Quadkey Library for working with Quadkeys in solidity
* The Quad Space Time Protocol


# Get started
* install truffle: https://github.com/trufflesuite/truffle
* install ganache client node for testing: http://truffleframework.com/ganache/
```
%> yarn
```
* Test something:
```
%> truffle test test/token/QuadToken.test.js
%> truffle test test/token/Capped721DutchCrowdsale.test.js
```
---

# Binary Quadkey Format

A uint64 quadkey, '03120312', looks like 

desc| quadkey | undefined | zoom level
--- | --- | --- | --- 
bitmask | 0-n | n-57 | 58-63
bits | 0b0011011000110110 | 0000000000000000000000000000000000000000000 | 01000
data | quadkey '03120312' | undefined | zoom level 8


# Protocols

## Quad Space Time Protocol v1
This version 1.0 is what we will release with LayerOne's go-to-market crypto learning game, LandRush. We will use existing off-chain binary quadkey libraries, in addition to the QuadKeylib we are building to efficiently store as DB keys.  In this proof of concept protocol, the uint64 binary quadkey fits well within the bounds of a single uint256.

Here's the standard quadkey bit format:

Size | uint64 | uint196
--- | --- | ---
bitmask | 0-63 | 64-255
contents | Binary Quadkey | Extra Space

## Quad Space Bit-packed Protocol v2.0
A more scalable solution to incorporate 3D space and time would be to simply bitpack the remaining 196 bits with the another level of precision, altitude and time using bitpacking in a single 256bit integer.  So, the first 64 bits for the high level binary quadkey.  Then a second 64bits as a subdivision of the first binary quadkey making the 2d precision get down to the nanometer scale.  Then, the third 64 bits would be reserved for altitude, and the fourth for a 64bit unix time.

Here's the format of this proposal:

Size | uint64 | uint64 | uint64 | uint64
--- | --- | --- | --- | ---
bitmask | 0-63 | 64-127 | 128-195 | 196-255
contents | Binary Quadkey | 2nd Sub-Binary Quadkey | Altitude | Time

One great advantage of this proposal is its backward compatability with v1.0


## Quad Space Time Protocol v2.1 (QST2)
What is really interesting and will effectively future proof the Quad Space Time Protocol is a new concept of a four dimensional quad key.  To make this truly increadible advancement in geo-space-time indexing, we would like to get community feedback from the ground floor.

In a single unsigned 256 bit integer one could isolate geo-spacial-temporal identifiers that can be translated to lat, lng, altitude (meters), and time (seconds), to extremely high levels of precision.  On the order of nano-meters and nano-seconds. All this is deserving of a white paper, which will be underway shortly.

It is not impossible to visualize a 4 dimension quadkey. First, imagine a quadkey at a given zoom level.  Next, stretch that plane into the 3rd dimension (making a quadkey cube).  Then, add the fourth dimension by lining up the 3d cube spaces into an array of cube spaces that effectively arranges the quadcube spaces into a quadkey divided time space.

Given a uint256, we can have a zoom level of 6 bits to allow 62 zoom levels as apposed to 29 in protocol v1.  The format would be as follows:

Size | uint248 | (6 bits) | (4 bits)
--- | --- | --- | ---
bitmask | 0-247 | 248-253 | 254-255
contents | 4D QuadSpaceTime | precision (zoom level) | extra space









