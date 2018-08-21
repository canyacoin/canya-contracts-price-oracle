pragma solidity ^0.4.11;

import "./SmartToken.sol";

contract MyERC20RelaySmartToken is SmartToken {

    function MyERC20RelaySmartToken(string _name, string _symbol, uint8 _decimals)
        SmartToken(_name, _symbol, _decimals)
    {
    }
}