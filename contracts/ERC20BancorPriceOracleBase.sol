pragma solidity ^0.4.23;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}


/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
        @dev constructor
    */
    function Owned() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

/*
    Interface to interact with deployed BancorConverter contract
*/
interface BancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256);
}

/**
 * @title Base ERC20 Bancor Price Oracle
 * @author Alex Scott (@alsco77) (CanYa)
 * @dev Contains current addresses of constant 
 */
contract ERC20BancorPriceOracleBase is Owned {

    IERC20Token public BNT; 
    IERC20Token internal DAI;

    BancorConverter internal DAIBNTConverter;

    /** 
      * @dev Constructor to set up base properties
      * @param _bntToken Address of deployed BNT
      * @param _daiToken Address of deployed DAI token
      * @param _daiBntConverter Address of deployed BancorConverter for BNT - DAI
      */
    constructor(address _bntToken, address _daiToken, address _daiBntConverter){
        BNT = IERC20Token(_bntToken);
        DAI = IERC20Token(_daiToken);
        DAIBNTConverter = BancorConverter(_daiBntConverter);
    }

    /** 
      * @dev How many DAI can I get with this BNT?
      * @param _amountBNT Amount to convert
      * @return uint256 Amount of DAI
      */
    function getBNTDAIConversion(uint256 _amountBNT) public view returns (uint256) {
        return DAIBNTConverter.getReturn(BNT, DAI, _amountBNT);
    }

    /** 
      * @dev How many BNT can I get with this DAI?
      * @param _amountDAI Amount to convert
      * @return uint256 Amount of BNT
      */
    function getDAIBNTConversion(uint256 _amountDAI) public view returns (uint256) {
        return DAIBNTConverter.getReturn(DAI, BNT, _amountDAI);
    }
}