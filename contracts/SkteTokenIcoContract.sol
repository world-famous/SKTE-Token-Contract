pragma solidity 0.4.24;


import "./SafeMath.sol";
import "./Ownable.sol";
import "./SkteToken.sol";

contract SkteTokenIcoContract  is Ownable{
    using SafeMath for uint256;
    SkteToken public skte;
	uint256 public  softcap = 500000 * 1 ether;
	uint256 public  hardcap = 20000000 * 1 ether;
	bool    public  reached = false;
	uint    public  startTime ;
	uint    public  endTime ;
	uint256 public   rate = 200;
	uint256 public   remain;
    address[] public investors;

	mapping  (address => uint256)    public   investor_token;

    mapping(address => bool) public isWhitelisted;
	mapping(address => bool) public isAdminlisted;

	event WhitelistSet(address indexed _address, bool _state);
	event AdminlistSet(address indexed _address, bool _state);
	event BuyTokens(address indexed beneficiary, uint256 value, uint256 amount, uint time);
    event ManageICOResult(uint time);

	constructor(address token, uint _startTime, uint _endTime) public{
        require(token != address(0));
        require(_startTime > 0);
        require(_endTime > 0);
		skte = SkteToken(token);
		require(skte.owner() == msg.sender);
		
		startTime = _startTime; // 1530450000 2018-07-01 9:AM EDT
		endTime = _endTime; // 1535806800 2018-09-01 9:AM EDT
		remain = hardcap;
	}

    modifier onlyOwners() { 
		require (isAdminlisted[msg.sender] == true || msg.sender == owner); 
		_; 
	}

	modifier onlyWhitelisted() { 
		require (isWhitelisted[msg.sender] == true); 
		_; 
	}

	  // fallback function can be used to buy tokens
	function () public payable onlyWhitelisted{
		buyTokens(msg.sender);
	}

	// low level token purchase function
	function buyTokens(address beneficiary) public payable onlyWhitelisted{
        require(beneficiary != address(0));
        require(msg.value > 0);
		buyTokens(beneficiary, msg.value);
	}

	function buyTokens(address beneficiary, uint256 weiAmount) internal {
		require(beneficiary != address(0));
		require(validPurchase(weiAmount));

		// calculate token amount to be sent
		uint256 tokens = weiAmount.mul(rate);
		
		if(remain.sub(tokens) <= 0){
			reached = true;
			uint256 real = remain;
			remain = 0;
			uint256 refund = weiAmount - real.div(rate);
			beneficiary.transfer(refund);
			registerTokenToInvestor(beneficiary, real);
			emit BuyTokens(beneficiary, weiAmount.sub(refund), real, now);
		} else{
			remain = remain.sub(tokens);
			registerTokenToInvestor(beneficiary, tokens);
			emit BuyTokens(beneficiary, weiAmount, tokens, now);
		}

	}

	function registerTokenToInvestor(address beneficiary, uint256 tokenamount) internal {
        require(beneficiary != address(0));
        require(tokenamount > 0);
		if(investor_token[beneficiary] > 0)
			investors.push(beneficiary);
		investor_token[beneficiary] = investor_token[beneficiary] + tokenamount;
	}

	function transferTokenToInvestors() internal {
		for (uint i=0; i<investors.length; i++) {
			skte.transfer(investors[i], investor_token[investors[i]]);
		}
	}

	function refundFunds() internal {
		for (uint i=0; i<investors.length; i++) {
			investors[i].transfer(investor_token[investors[i]].div(rate));
		}
	}

	// low level transfer token
	// override to create custom token transfer mechanism, eg. pull pattern
	function transferToken(address beneficiary, uint256 tokenamount) internal {
        require(beneficiary != address(0));
        require(tokenamount > 0);
		skte.transfer(beneficiary, tokenamount);
	}

	// send ether to the fund collection wallet
	// override to create custom fund forwarding mechanisms
	function forwardFunds(uint256 weiAmount) internal {
        require(weiAmount > 0);
		owner.transfer(weiAmount);
	}

	// @return true if the transaction can buy tokens
	function validPurchase(uint256 weiAmount) internal view returns (bool) {
		bool withinPeriod = now > startTime && now <= endTime;
		bool nonZeroPurchase = weiAmount > 0 ether;
		bool withinSale = reached ? false : true;
		return withinPeriod && nonZeroPurchase && withinSale;
	}

    function setAdminlist(address _addr, bool _state) public onlyOwner {
        require(_addr != address(0));
		isAdminlisted[_addr] = _state;
		emit AdminlistSet(_addr, _state);
	}

    function setWhitelist(address _addr) public onlyOwners {
        require(_addr != address(0));
        isWhitelisted[_addr] = true;
        emit WhitelistSet(_addr, true);
    }

    /// @notice Set whitelist state for multiple addresses
    function setManyWhitelist(address[] _addr) public onlyOwners {
        for (uint256 i = 0; i < _addr.length; i++) {
            setWhitelist(_addr[i]);
        }
    }

	// @return true if presale event has ended
	function hasEnded() public view returns (bool) {
		bool outPeriod = now > endTime;
		bool outSale = reached ? true : false;
		return outPeriod || outSale;
	}

	// @return true if presale has started
	function hasStarted() public view returns (bool) {
		return now >= startTime;
	}

	function setRate(uint256 _rate) public onlyOwner returns (bool) {
        require(rate > 0);
		require (now >= startTime && now <= endTime);
		rate = _rate;
        return true;
	}

	function manageICOResult() public onlyOwner returns (bool) {
		require(now > endTime);
		if(hardcap - remain > softcap){
			transferTokenToInvestors();
			owner.transfer(address(this).balance);
			skte.burn(remain);
			remain = 0;
		}else{
			refundFunds();
		}

		emit ManageICOResult(now);
		return true;
	}

    function checkInvestorHoldingToken(address investor) public view returns (uint256){
        require(investor != address(0));
        return skte.balanceOf(investor);
    }

	function kill() public onlyOwner{
        selfdestruct(owner);
    }
}