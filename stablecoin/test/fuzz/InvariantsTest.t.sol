// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

// Invariants to think about

// 1. The debt should never exceed the collateral. i.e DSCTotalSupply < TotalCollateralValueInUSD
// 2. Getter view functions should never revert (everGreen functions).
