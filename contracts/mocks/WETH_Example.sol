pragma solidity ^0.8.20;

import "@uniswap/universal-router/contracts/interfaces/external/IWETH9.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// This is a simplified WETH mock implementing the IWETH9 interface.
contract WETH is IWETH9, Context {

    // Approval and Transfer events are inherited from IWETH9
    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    uint public override totalSupply;

    fallback() external payable {
        deposit();
    }
    receive() external payable {
        deposit();
    }

    function deposit() public payable virtual override {
        balanceOf[_msgSender()] += msg.value;
        totalSupply += msg.value;
        emit Deposit(_msgSender(), msg.value);
        emit Transfer(address(0), _msgSender(), msg.value); // Minting event
    }

    function withdraw(uint wad) public virtual override {
        address sender = _msgSender();
        require(balanceOf[sender] >= wad, "WETH: withdraw amount exceeds balance");
        balanceOf[sender] -= wad;
        totalSupply -= wad;
        emit Withdrawal(sender, wad);
        emit Transfer(sender, address(0), wad); // Burning event
        payable(sender).transfer(wad);
    }

    function approve(address guy, uint wad) public virtual override returns (bool) {
        allowance[_msgSender()][guy] = wad;
        emit Approval(_msgSender(), guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public virtual override returns (bool) {
        return _transfer(_msgSender(), dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public virtual override returns (bool) {
        address spender = _msgSender();
        uint currentAllowance = allowance[src][spender];
        if (currentAllowance != type(uint).max) {
            require(currentAllowance >= wad, "WETH: transfer amount exceeds allowance");
            unchecked {
                 allowance[src][spender] = currentAllowance - wad;
            }
        }
        return _transfer(src, dst, wad);
    }

    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(balanceOf[src] >= wad, "WETH: transfer amount exceeds balance");
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        emit Transfer(src, dst, wad);
        return true;
    }
} 