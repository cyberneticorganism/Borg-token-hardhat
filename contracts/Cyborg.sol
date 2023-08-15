// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint amountOut);
}


contract Cyborg is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {
    address payable devWallet;
    mapping(address => bool) private isExcludedFromTax;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public buyTax = 0;
    uint256 public sellTax = 0;
    uint256 public constant MAX_TAX = 500; // Represents 5% (basis points)
    address payable uniswapPair;

    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // ISwapRouter public immutable swapRouter;
    

    constructor() ERC20("Cyborg", "BORG") ERC20Permit("Cyborg") {
        //  IUniswapRouter public constant uniswapRouter = swapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Mainnet Uniswap V2 router address
        // uniswapPair = payable(factory.createPool(address(this), address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6), 500));
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

    function setUniswapPair(address payable _uniSwapPair) external onlyOwner {
        uniswapPair = _uniSwapPair;
    }
    
    function setDevWallet(address payable _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    function excludeFromTax(address _account) external onlyOwner {
        isExcludedFromTax[_account] = true;
    }

    function includeInTax(address _account) external onlyOwner {
        isExcludedFromTax[_account] = false;
    }

        // checks whether the transfer is a swap
    function _isSwap(address sender_, address recipient_) internal view returns (bool result) {
        if (sender_ == uniswapPair || recipient_ == uniswapPair) {
            result = true;
        }
    }
    
    function convertBorgToEth(uint256 borgAmount) public payable returns (uint amountOut) {
        require(borgAmount > 0, "Must pass non 0 Borg amount");

        address _tokenIn = address(this);
        address _tokenOut = WETH;
        
        uint24 poolFee = 3000;
        
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: devWallet,
                deadline: block.timestamp + 15,
                amountIn: borgAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
         amountOut = router.exactInputSingle(params);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (!isExcludedFromTax[recipient] && amount > maxPurchaseAmount()) {
            revert("Transfer amount exceeds the max purchase limit.");
        }

        uint256 taxAmount = calculateBuyTax(amount);
        uint256 newAmount = amount - taxAmount;
        if(_isSwap(msg.sender, recipient)) {
            super.transfer(recipient, newAmount);
            if (taxAmount > 0) {
                convertBorgToEth(taxAmount);
            }
        } else {
            super.transfer(recipient, amount);
        } 

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (!isExcludedFromTax[sender] && amount > maxPurchaseAmount()) {
            revert("Transfer amount exceeds the max purchase limit.");
        }

        uint256 taxAmount = calculateSellTax(amount);
        uint256 newAmount = amount - taxAmount;
        if(_isSwap(msg.sender, recipient)) {
            super.transferFrom(sender, recipient, newAmount);
            if (taxAmount > 0) {
                convertBorgToEth(taxAmount);
            }

        } else {
            super.transferFrom(sender, recipient, amount);
        }

        return true;
    }

    function maxPurchaseAmount() public view returns (uint256) {
        return IERC20(address(this)).totalSupply() / 200; // 0.5% of total supply
    }

    function getUniswapPair() public view returns (address payable) {
        // emit(uniswapPair);
        return uniswapPair;
    }
}
