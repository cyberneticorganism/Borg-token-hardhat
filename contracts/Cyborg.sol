// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Cyborg is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {
    uint256 public taxPercentage = 5;
    address payable devWallet;
    constructor(uint256 initialSupply) ERC20("Cyborg", "BORG") ERC20Permit("Cyborg") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
        devWallet = payable(msg.sender);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function updateTax(uint256 newTaxPercent) public onlyOwner returns (bool) {
        taxPercentage = newTaxPercent;
        return true;
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

    function calculateTax(uint256 amount) private view returns (uint256) {
        return (amount * taxPercentage) / 100; //Calculate 
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 tax = calculateTax(amount);
        uint256 amountAfterTax = amount - tax;
        super.transfer(recipient, amountAfterTax); // Transfer the amount after deducting tax

        if (tax > 0) {
            super.transfer(address(devWallet), tax); // Transfer the tax to the contract address
        }

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 tax = calculateTax(amount);
        uint256 amountAfterTax = amount - tax;
        super.transferFrom(sender, recipient, amountAfterTax); // Transfer the amount after deducting tax

        if (tax > 0) {
            super.transferFrom(sender, address(this), tax); // Transfer the tax to the contract address
        }

        return true;
    }
}
