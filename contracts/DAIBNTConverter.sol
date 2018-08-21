pragma solidity ^0.4.21;

import "./BancorConverter.sol";

contract DAIBNTConverter is BancorConverter {

    function DAIBNTConverter(
        ISmartToken _token,
        IContractRegistry _registry,
        uint32 _maxConversionFee,
        IERC20Token _connectorToken,
        uint32 _connectorWeight
    )
        public
        BancorConverter(_token, _registry, _maxConversionFee, _connectorToken, _connectorWeight)
    {
    }
}