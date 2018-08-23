pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


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

    using SafeMath for uint256;

    IERC20Token public BNT; 
    IERC20Token public DAI;

    BancorConverter public DAIBNTConverter;

    /** 
      * @dev Constructor to set up base properties
      * @param _bntToken Address of deployed BNT
      * @param _daiToken Address of deployed DAI token
      * @param _daiBntConverter Address of deployed BancorConverter for BNT - DAI
      */
    constructor(address _bntToken, address _daiToken, address _daiBntConverter){
        require(address(0) != _bntToken && address(0) != _daiToken && address(0) != _daiBntConverter, "Must contain valid addresses");
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
        uint256 decimals = BNT.decimals();
        uint256 valueOfOneBNT = DAIBNTConverter.getReturn(BNT, DAI, 10 ** decimals);
        return valueOfOneBNT.mul(_amountBNT).div(10 ** decimals);
    }

    /** 
      * @dev How many BNT can I get with this DAI?
      * @param _amountDAI Amount to convert
      * @return uint256 Amount of BNT
      */
    function getDAIBNTConversion(uint256 _amountDAI) public view returns (uint256) {
        uint256 decimals = DAI.decimals();
        uint256 valueOfOneDAI = DAIBNTConverter.getReturn(DAI, BNT, 10 ** decimals);
        return valueOfOneDAI.mul(_amountDAI).div(10 ** decimals);
    }

    /** 
      * @dev Update the address of BNT token
      * @param _bntToken Address
      */
    function updateBNTAddress(address _bntToken) external
    ownerOnly {
        require(address(0) != _bntToken && _bntToken != address(BNT), "Must be a new, valid address");
        BNT = IERC20Token(_bntToken);
    }

    /** 
      * @dev Update the address of DAI token
      * @param _daiToken Address
      */
    function updateDAIAddress(address _daiToken) external
    ownerOnly {
        require(address(0) != _daiToken && _daiToken != address(DAI), "Must be a new, valid address");
        DAI = IERC20Token(_daiToken);
    }

    /** 
      * @dev Update the address of dai-bnt converter
      * @param _daiBntConverter Address
      */
    function updateConverterAddress(address _daiBntConverter) external
    ownerOnly {
        require(address(0) != _daiBntConverter && _daiBntConverter != address(DAIBNTConverter), "Must be a new, valid address");
        DAIBNTConverter = BancorConverter(_daiBntConverter);
    }
}