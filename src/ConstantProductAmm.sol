// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title ConstantProductAmm
/// @notice Simple Constant Product AMM implementation
/// @dev This is a simple example and should not be used on mainnet
contract ConstantProductAmm {
    /// @notice ERC20 token0 of the pair
    IERC20 public immutable token0;
    /// @notice ERC20 token1 of the pair
    IERC20 public immutable token1;

    /// @notice internal balance of token0
    uint256 public reserve0;
    /// @notice internal balance of token1
    uint256 public reserve1;

    /// @notice total shares (for liquidity)
    uint256 public totalSupply;
    /// @notice number of shares per user (for liquidity)
    mapping(address => uint256) public balanceOf;

    /// @notice Initialize the contract with a pair of token addresses
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /// @notice Mints shares to the user
    /// @param _to address of the user who receives shares minted
    /// @param _amount the amount of shares to mint
    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] = balanceOf[_to] + _amount;
        totalSupply = totalSupply + _amount;
    }

    /// @notice Burns shares from the user
    /// @param _from address of the user which shares are burned
    /// @param _amount the amount of shares to burn
    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] = balanceOf[_from] - _amount;
        totalSupply = totalSupply - _amount;
    }

    /// @notice Update the internal balance of token0 and token1
    function _update(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    /// @notice Perfrom a swap specifying token and amount in
    /// @param _tokenIn address of the token we want to swap
    /// @param _amountIn amount of token '_tokenIn' we want to swap
    /// @return amountOut amount of token we get after the swap
    function swap(
        address _tokenIn,
        uint256 _amountIn
    ) external returns (uint256 amountOut) {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "Invalid token"
        );
        require(_amountIn > 0, "amountIn = 0");

        
        // Check if tokenIn is token0 or token1
        bool isToken0 = _tokenIn == address(token0);
        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isToken0
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);

        // Transfer tokenIn to the contract
        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        // Calculate token out with fees 0.3%
        uint amountInWithFee = (_amountIn * 997) / 1000;
        // dy = (y * dx) / (x + dx)
        amountOut =
            (reserveOut * amountInWithFee) /
            (reserveIn + amountInWithFee);
        // Transfer token out to msg.sender
        tokenOut.transfer(msg.sender, amountOut);
        // Update the reserves
        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    /// @notice Add liquidity to the pool and get shares back
    /// @param _amount0 amount of the first token to add to the pool
    /// @param _amount1 amount of the second token to add to the pool
    /// @return shares amount of shares given to the liquidity provider
    function addLiquidty(
        uint256 _amount0,
        uint256 _amount1
    ) external returns (uint256 shares) {
        // Transfer token0 and token1 to the contract
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        // dy / dx = y / x
        // where dy = _amount1, dx = _amount0, y = reserve1, x = reserve0
        if (reserve0 > 0 || reserve1 > 0) {
            require(
                reserve0 * _amount1 == reserve1 * _amount0,
                "dy / dx != y / x"
            );
        }
        // Mint shares
        // value of liqudity = sqrt(x*y)
        // s = dx / x * T = dy / y * T
        if(totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min(
                (_amount0 * totalSupply) / reserve0, 
                (_amount1 * totalSupply) / reserve1
                );
        }
        require(shares > 0, "shares = 0");
        // Mint the shares to the msg.sender
        _mint(msg.sender, shares);
        // Update reserves
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /// @notice Remove liquidity from the pool by providing '_shares' and get back tokens
    /// @param _shares give amount of shares in exchange for token0 and token1
    /// @return amount0 amount of token0 transferred to msg.sender
    /// @return amount1 amount of token1 transferred to msg.sender
    function removeLiquidity(uint256 _shares) external returns(uint256 amount0, uint256 amount1) {
        // Calculate amount0 and amount1 to withdraw
        // dx = s / T * x
        // dy = s / T * y
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        amount0 = _shares * balance0 / totalSupply;
        amount1 = _shares * balance1 / totalSupply;
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");
        
        // Burn shares
        _burn(msg.sender, _shares);
        
        // Update reserves
        _update(balance0 - amount0, balance1 - amount1);

        // Transfer tokens to msg.sender
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }

    /// @notice Calculate the square root of a number
    function _sqrt(uint y) private pure returns(uint z) {
        if(y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            } else if (y != 0) {
                z = 1;
            }
        }
    }

    /// @notice Get the minimum of two provided numbers
    function _min(uint x, uint y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
