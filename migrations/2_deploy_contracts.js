const numberToBN = require("number-to-bn");
const BigNumber = require("bignumber.js");
const SkteToken = artifacts.require("SkteToken");
const SkteTokenIcoContract = artifacts.require("SkteTokenIcoContract");
const SafeMath = artifacts.require("SafeMath");
const token_amount = numberToBN(new BigNumber(20000000*10**18));
const startTime = Math.floor(new Date().getTime()/1000);
const endTime = startTime + 1440*60;


module.exports = async function(deployer) {
	await deployer.deploy(SafeMath);

	const safeMath = await SafeMath.deployed();

	deployer.link(safeMath, [SkteToken, SkteTokenIcoContract]);

	await deployer.deploy(SkteToken);
  
	const skteToken = await SkteToken.deployed();
	const SkteToken_address = await skteToken.address;

	await deployer.deploy(SkteTokenIcoContract, SkteToken_address, startTime, endTime);
	const skteTokenIcoContract = await SkteTokenIcoContract.deployed();
	const SkteTokenIcoContract_address = await skteTokenIcoContract.address;
	skteToken.transfer(SkteTokenIcoContract_address, token_amount);
  };