// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ConstantProductAmm {
    /// @notice ERC20 token0 of the pair
    IERC20 public immutable token0;
    /// @notice ERC20 token1 of the pair
    IERC20 public immutable token1;

    /// @notice internal balance of token0
    uint256 public reserves0;
    /// @notice internal balance of token1
    uint256 public reserves1;

    /// @notice total shares (for liquidity)
    uint256 public totalSupply;
    /// @notice number of shares per user (for liquidity)
    mapping(address => uint256) public balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }
}
