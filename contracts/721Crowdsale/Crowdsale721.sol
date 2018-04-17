pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../tokens/QuadToken.sol";

/**
 * @title Crowdsale721
 * @dev Crowdsale721 is a base contract for managing a 721 token crowdsale.
 * It is strongly based on zeppelin solidity ERC20 crowdsale contract
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will mint their tokens. 
 * Funds collected are forwarded to a wallet as they arrive.
 */
contract Crowdsale721 {
  
  using SafeMath for uint256;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // dynamic price of token
  uint256 public startPrice;

  // amount of raised money in wei
  uint256 public weiRaised;

  // This token exposes minting on the 721 standard token contract
  // Either be owner of the NFT contract for minting purposes, 
  // or share the same owner to allow minting from here
  QuadToken public nftContract_;

  /* 
    @dev This contract owns the token contract until the ILO is over
  */
  function Crowdsale721(
    uint256 _startTime, 
    uint256 _endTime, 
    uint256 _price, 
    address _wallet,
    address _nftContract
  ) 
    public 
  {
    require(_endTime >= _startTime);

    wallet = _wallet;
    startTime = _startTime;
    endTime = _endTime;
    startPrice = _price;
    nftContract_ = QuadToken(_nftContract);
  }
  
  event LandsalePurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint8 numTokens);

  // low level token purchase function
  function buyTokens(
    uint64[] _tokenIds,
    address _beneficiary
  ) 
    public 
    payable 
  {
    require(_beneficiary != address(0));
    require(validPurchase(_tokenIds));
    
    uint256 weiAmount = msg.value;

    // update state
    weiRaised = weiRaised.add(weiAmount);

    emit LandsalePurchase(msg.sender, _beneficiary, weiAmount, uint8(_tokenIds.length));

    forwardFunds();

    // mint externally on mintable crowdsale
    nftContract_.mint(_beneficiary, _tokenIds);
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @param _tokenIds - pass the tokens to price
  // @return true if the transaction can buy tokens
  // override to change the price/quantity rates
  function validPurchase(uint64[] _tokenIds) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool correctPayment = msg.value >= price(_tokenIds);
    return withinPeriod && correctPayment;
  }

  // calculates the price for all tokens
  // override to customize the pricing for tokens being minted
  function price(uint64[] _tokenIds) public view returns (uint256) {
    return startPrice.mul(_tokenIds.length);
  }
}
