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
