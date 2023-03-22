// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {ConstantProductAmm} from "../src/ConstantProductAmm.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Constructor is Test {
    ERC20 public token0;
    ERC20 public token1;
    ConstantProductAmm public CPAMM;

    function test_InitializeTokensCorrectly() public {
        token0 = new ERC20("Token0", "T0");
        token1 = new ERC20("Token1", "T1");
        CPAMM = new ConstantProductAmm(address(token0), address(token1));
        assertEq(address(CPAMM.token0()), address(token0));
    }
}

contract AddLiquidity is Test {
    ERC20 public token0;
    ERC20 public token1;
    ConstantProductAmm public CPAMM;
    address alice = makeAddr("Alice");

    uint256 constant STARTING_BALANCE = 1_000_000e18;
    uint256 public constant MINIMUM_LIQUIDITY = 1e3;

    function setUp() public {
        token0 = new ERC20("Token0", "T0");
        token1 = new ERC20("Token1", "T1");
        CPAMM = new ConstantProductAmm(address(token0), address(token1));

        deal(address(token0), address(this), STARTING_BALANCE);
        deal(address(token1), address(this), STARTING_BALANCE);

        deal(address(token0), address(alice), STARTING_BALANCE);
        deal(address(token1), address(alice), STARTING_BALANCE);
    }

    // helper function
    function _sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // helper function
    function _min(uint x, uint y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    function test_AddLiquidity() public {
        token0.approve(address(CPAMM), type(uint256).max);
        token1.approve(address(CPAMM), type(uint256).max);
        uint256 amount0 = 1e18;
        uint256 amount1 = 1e18;
        CPAMM.addLiquidity(amount0, amount1);

        // shares - sqrt(x*y)
        uint256 shares = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        assertEq(CPAMM.balanceOf(address(this)), shares);
        assertEq(CPAMM.totalSupply(), shares);
        // reserve
        assertEq(CPAMM.reserve0(), amount0);
        assertEq(CPAMM.reserve1(), amount1);
        // user token balance
        assertEq(token0.balanceOf(address(this)), STARTING_BALANCE - amount0);
        assertEq(token1.balanceOf(address(this)), STARTING_BALANCE - amount1);
    }

    function testFuzz_AddLiquidity(uint256 amount0, uint256 amount1) public {
        amount0 = bound(amount0, MINIMUM_LIQUIDITY + 1, STARTING_BALANCE);
        amount1 = bound(amount1, MINIMUM_LIQUIDITY + 1, STARTING_BALANCE);

        token0.approve(address(CPAMM), type(uint256).max);
        token1.approve(address(CPAMM), type(uint256).max);
        CPAMM.addLiquidity(amount0, amount1);

        // shares - sqrt(x*y)
        uint256 shares = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
        assertEq(CPAMM.balanceOf(address(this)), shares);
        assertEq(CPAMM.totalSupply(), shares + MINIMUM_LIQUIDITY);
        // reserve
        assertEq(CPAMM.reserve0(), token0.balanceOf(address(CPAMM)));
        assertEq(CPAMM.reserve1(), token1.balanceOf(address(CPAMM)));
        // user token balance
        assertEq(token0.balanceOf(address(this)), STARTING_BALANCE - amount0);
        assertEq(token1.balanceOf(address(this)), STARTING_BALANCE - amount1);
    }

    // function testFuzz_AddLiquidity_TwoTimes(
    //     uint256 amount0,
    //     uint256 amount1,
    //     uint256 amount0_Alice,
    //     uint256 amount1_Alice
    // ) public {
    //     testFuzz_AddLiquidity(amount0, amount1);

    //     amount0_Alice = bound(
    //         amount0_Alice,
    //         MINIMUM_LIQUIDITY + 1,
    //         STARTING_BALANCE
    //     );
    //     amount1_Alice = bound(
    //         amount1_Alice,
    //         MINIMUM_LIQUIDITY + 1,
    //         STARTING_BALANCE
    //     );
    //     vm.startPrank(alice);
    //     token0.approve(address(CPAMM), type(uint256).max);
    //     token1.approve(address(CPAMM), type(uint256).max);
    //     CPAMM.addLiquidity(amount0_Alice, amount1_Alice);

    //     // shares - sqrt(x*y)
    //     uint256 shares = _min(
    //         (amount0_Alice * CPAMM.totalSupply()) / CPAMM.reserve0(),
    //         (amount1_Alice * CPAMM.totalSupply()) / CPAMM.reserve1()
    //     );

    //     assertEq(CPAMM.balanceOf(address(alice)), shares);
    //     // assertEq(CPAMM.totalSupply(), _sqrt(amount0 * amount1) + shares);
    //     // // reserve
    //     // assertEq(CPAMM.reserve0(), token0.balanceOf(address(CPAMM)));
    //     // assertEq(CPAMM.reserve1(), token1.balanceOf(address(CPAMM)));
    //     // // user token balance
    //     // assertEq(
    //     //     token0.balanceOf(address(alice)),
    //     //     STARTING_BALANCE - (amount0 + amount0_Alice)
    //     // );
    //     // assertEq(
    //     //     token1.balanceOf(address(alice)),
    //     //     STARTING_BALANCE - (amount1 + amount1_Alice)
    //     // );
    // }
}

contract RemoveLiquidity is Test {}

contract Swap is Test {
    ERC20 public token0;
    ERC20 public token1;
    ConstantProductAmm public CPAMM;

    uint256 startingBalance = 100e18;

    function setUp() public {
        token0 = new ERC20("Token0", "T0");
        token1 = new ERC20("Token1", "T1");
        CPAMM = new ConstantProductAmm(address(token0), address(token1));

        deal(address(token0), address(CPAMM), startingBalance);
        deal(address(token1), address(CPAMM), startingBalance);

        deal(address(token0), address(this), startingBalance);
        deal(address(token1), address(this), startingBalance);
    }

    function test_SwapToken0ForToken1() public {
        token0.approve(address(CPAMM), type(uint256).max);
        uint256 tokenOut = CPAMM.swap(address(token0), 10e18);
        console.log("TokenOut:", tokenOut);
        // TokenOut = 0 because of reserve0 = 0 and reserve1 = 0

        assertEq(token0.balanceOf(address(this)), startingBalance - 10e18);
        assertEq(token0.balanceOf(address(CPAMM)), startingBalance + 10e18);

        assertEq(token1.balanceOf(address(this)), startingBalance + tokenOut);
        assertEq(token1.balanceOf(address(CPAMM)), startingBalance - tokenOut);
    }
}
