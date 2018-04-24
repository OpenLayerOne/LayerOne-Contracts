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
--- | --- | --- | --- | ---
bitmask | 0-n | n-57 | 58-63
bits | 0b0011011000110110 | 0000000000000000000000000000000000000000000 | 01000
data | quadkey '03120312' | undefined | zoom level 8


# Protocols

## Quad Space Time Protocol v1 (QST1)
For version 1.0, we will use existing off-chain binary quadkey libraries, in addition to the QuadKeylib we are building to efficiently store as DB keys.  In this proof of concept protocol, the uint64 binary quadkey fits well within the bounds of a single uint256.

Here's the standard quadkey bit format:

Size | uint64 | uint64 | uint128
--- | --- | --- | --- | ---
bitmask | 0-63 | 64-127 | 128-255
contents | Binary Quadkey | Unix 64-bit Timestamp | Extra Space

By storing time (and potentially altitude) seperate from the quad-space address we limit precision of the quadkey to uint64 space (29 zoom levels of precision).  Things get much more precise if we expand to a uint256 space:

## Quad Space Time Protocol v2 (QST2)
What is really interesting and will effectively future proof the Quad Space Time Protocol is a new concept of a four dimensional quad key.  To make this truly increadible advancement in geo-space-time indexing, we would like to get community feedback from the ground floor.

In a single unsigned 256 bit integer one could isolate geo-spacial-temporal identifiers that can be translated to lat, lng, altitude (meters), and time (seconds), to extremely high levels of precision.  On the order of nano-meters and nano-seconds. All this is deserving of a white paper, which will be underway shortly.

It is not impossible to visualize a 4 dimension quadkey. First, imagine a quadkey at a given zoom level.  Next, stretch that plane into the 3rd dimension (making a quadkey cube).  Then, add the fourth dimension by lining up the 3d cube spaces into an array of cube spaces that effectively arranges the quadcube spaces into a quadkey divided time space.

Given a uint256, we can have a zoom level of 6 bits to allow 62 zoom levels as apposed to 29 in protocol v1.  The format would be as follows:

Size | uint248 | (6 bits) | (4 bits)
--- | --- | --- | ---
bitmask | 0-247 | 248-253 | 254-255
contents | 4D QuadSpaceTime | precision (zoom level) | extra space









