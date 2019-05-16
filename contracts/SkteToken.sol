pragma solidity 0.4.24;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
/**
 * The contractName contract does this and that...
 */


contract SkteToken is ERC20, Ownable {

    using SafeMath for uint256;

    uint256  public  totalSupply = 20000000 * 1 ether;

    mapping  (address => uint256)             public          _balances;
    mapping  (address => mapping (address => uint256)) public  _approvals;


    string   public  name = "SK TEST";
    string   public  symbol = "SKTE";
    uint256  public  decimals = 18;

    event Mint(uint256 wad);
    event Burn(uint256 wad);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

    constructor () public{
        _balances[msg.sender] = totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        require(dst != address(0));
        require(wad > 0 && _balances[msg.sender] >= wad);
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        emit Transfer(msg.sender, dst, wad);
        return true;
    }
    
    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(src != address(0));
        require(dst != address(0));
        require(wad > 0 && _balances[src] >= wad && _approvals[src][msg.sender] >= wad);
        _approvals[src][msg.sender] = _approvals[src][msg.sender].sub(wad);
        _balances[src] = _balances[src].sub(wad);
        _balances[dst] = _balances[dst].add(wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        require(guy != address(0));
        require(wad > 0 && wad <= _balances[msg.sender]);
        _approvals[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function mint(uint256 wad) public onlyOwner returns (bool) {
        require(wad > 0);
        _balances[msg.sender] = _balances[msg.sender].add(wad);
        totalSupply = totalSupply.add(wad);
        emit Mint(wad);
        return true;
    }

    function burn(uint256 wad) public onlyOwner returns (bool)  {
        require(wad > 0 && wad <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(wad);
        totalSupply = totalSupply.sub(wad);
        emit Burn(wad);
        return true;
    }
}