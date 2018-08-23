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
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) external view returns (uint256);
}

/**
 * @title Base ERC20 Bancor Price Oracle interface
 */
contract ERC20BancorPriceOracleBase {
    IERC20Token public BNT; 
    function getBNTDAIConversion(uint256 _amountBNT) public view returns (uint256);
    function getDAIBNTConversion(uint256 _amountDAI) public view returns (uint256);
}

/**
 * @title ERC20 Bancor Price Oracle
 * @author Alex Scott (@alsco77) (CanYa)
 * @dev Used to get current conversion rates from ERC20 tokens on the Bancor network to DAI (stablecoin)
 * or BNT. Can be used as a trusted on chain price oracle for your token.
 */
contract ERC20BancorPriceOracle is Owned {

    using SafeMath for uint256;

    IERC20Token public MyERC20Token;
    BancorConverter public MyTokenConverter;
    ERC20BancorPriceOracleBase public OracleBase;

    /** 
      * @dev Contructor
      * @param _myERC20Token Address of your token 
      * @param _myTokenConverter Address of the BancorConverter contract for your token
      * @param _oracleBase Address of the oracle base containing BNT to DAI conversion
      */
    constructor(address _myERC20Token, address _myTokenConverter, address _oracleBase) {
        require(address(0) != _myERC20Token && address(0) != _myTokenConverter && address(0) != _oracleBase, "Must contain valid addresses");
        MyERC20Token = IERC20Token(_myERC20Token);
        MyTokenConverter = BancorConverter(_myTokenConverter);
        OracleBase = ERC20BancorPriceOracleBase(_oracleBase);
    }

    /** 
      * @dev Get DAI value of Token (How much USD are these tokens worth)
      * @param _tokenAmount Amount of your token to convert, (amount * 10**decimals)
      * @return Value of tokens in DAI
      */
    function getTokenToDai(uint256 _tokenAmount) external view returns (uint256) {
        uint256 decimals = MyERC20Token.decimals();
        uint256 valueOfOneToken = MyTokenConverter.getReturn(MyERC20Token, OracleBase.BNT(), 10 ** decimals);
        uint256 tokenValueInBNT = valueOfOneToken.mul(_tokenAmount).div(10 ** decimals);
        return OracleBase.getBNTDAIConversion(tokenValueInBNT);
    }

    /** 
      * @dev Get conversion rate of DAI to your tokens (How many tokens can I get with this USD)
      * @param _daiAmount Dai amount, remember (amount) * 10**18
      * @return Number of tokens
      */
    function getDaiToToken(uint256 _daiAmount) external view returns (uint256) {
        uint bntValueOfDai = OracleBase.getDAIBNTConversion(_daiAmount);
        uint256 decimals = OracleBase.BNT().decimals();
        uint256 valueOfOneBNT = MyTokenConverter.getReturn(OracleBase.BNT(), MyERC20Token, 10 ** decimals);
        return valueOfOneBNT.mul(bntValueOfDai).div(10 ** decimals);
    }

    /** 
      * @dev Update the address of my erc20 token
      * @param _myToken Address
      */
    function updateMyTokenAddress(address _myToken) external
    ownerOnly {
        require(address(0) != _myToken && _myToken != address(MyERC20Token), "Must be a new, valid address");
        MyERC20Token = IERC20Token(_myToken);
    }

    /** 
      * @dev Update the address of eth-bnt converter
      * @param _tokenConverter Address
      */
    function updateTokenConverterAddress(address _tokenConverter) external
    ownerOnly {
        require(address(0) != _tokenConverter && _tokenConverter != address(MyTokenConverter), "Must be a new, valid address");
        MyTokenConverter = BancorConverter(_tokenConverter);
    }

    /** 
      * @dev Update the address of oracle base contract
      * @param _oracleBase Address
      */
    function updateOracleBaseAddress(address _oracleBase) external
    ownerOnly {
        require(address(0) != _oracleBase && _oracleBase != address(OracleBase), "Must be a new, valid address");
        OracleBase = ERC20BancorPriceOracleBase(_oracleBase);
    }
}

