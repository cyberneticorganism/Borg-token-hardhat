// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Cyborg is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {
    address payable devWallet;
    mapping(address => bool) private isExcludedFromTax;

    uint256 public buyTax = 0;
    uint256 public sellTax = 0;
    uint256 public constant MAX_TAX = 500; // Represents 5% (basis points)

    constructor() ERC20("Cyborg", "BORG") ERC20Permit("Cyborg") {
        _mint(msg.sender, 214000000000000 * 10 ** decimals());
        devWallet = payable(msg.sender);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    function calculateBuyTax(uint256 _amount) internal view returns (uint256) {
        return (_amount * buyTax) / 10000; // Use basis points for percentage calculation
    }

    function calculateSellTax(uint256 _amount) internal view returns (uint256) {
        return (_amount * sellTax) / 10000; // Use basis points for percentage calculation
    }

    function setBuyTax(uint256 _buyTax) external onlyOwner {
        require(_buyTax <= MAX_TAX, "Buy tax exceeds the maximum limit.");
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        require(_sellTax <= MAX_TAX, "Sell tax exceeds the maximum limit.");
        sellTax = _sellTax;
    }

    function excludeFromTax(address _account) external onlyOwner {
        isExcludedFromTax[_account] = true;
    }

    function includeInTax(address _account) external onlyOwner {
        isExcludedFromTax[_account] = false;
    }



    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (!isExcludedFromTax[recipient] && amount > maxPurchaseAmount()) {
            revert("Transfer amount exceeds the max purchase limit.");
        }

        uint256 taxAmount = calculateBuyTax(amount);
        uint256 newAmount = amount - taxAmount;

        super.transfer(recipient, newAmount);

        if (taxAmount > 0) {
          super.transfer(address(this), taxAmount);
        }

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (!isExcludedFromTax[sender] && amount > maxPurchaseAmount()) {
            revert("Transfer amount exceeds the max purchase limit.");
        }

        uint256 taxAmount = calculateSellTax(amount);
        uint256 newAmount = amount - taxAmount;

        super.transferFrom(sender, recipient, newAmount);

        if (taxAmount > 0) {
            super.transferFrom(sender, address(this), taxAmount);
        }

        return true;
    }

    function maxPurchaseAmount() public view returns (uint256) {
        return IERC20(address(this)).totalSupply() / 200; // 0.5% of total supply
    }
}
