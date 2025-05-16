pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDC is ERC20, Ownable {
    constructor(address initialOwner) ERC20("USD Coin", "USDC") Ownable(initialOwner) {
        _mint(msg.sender, 1000000 * 10**decimals()); // Mint initial supply to deployer
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
} 