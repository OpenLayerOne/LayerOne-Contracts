pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

/*
    Land Rush Gold (LRG) Token contract
    This contract controls the creation of the Land Rush Gold, 
    and will be brought into the market via LayerOne's Land Rush Game.
    Btw, fun fact, when you pay with this token, and you give someone 50 LRG you can say,
    "Here's 50 Large."
    Initial supply 200,000,000.00 Large
*/
contract LRGToken is StandardToken {
    uint8 public constant decimals = 18;
    string public constant name = "Land Rush Gold";
    string public constant symbol = "LRG";

    /*
        Land Rush Gold (LRG) Token contract
        This constructs the contract and assigns initial supply to a vault
    */
     function LRGToken() public {
        totalSupply_ = 200000000 * 10**uint(decimals);
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
}