// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title DSCEngine
 * @author Richu A Kuttikattu
 * @notice This contract is the engine of the DSC StableCoin project. It handles all the logic that ensures the 1 token == $1 peg.
 * @notice It handles minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on MakerDAO DSS system
 *
 *
 * The system is designed to be as minimal as possible.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 */
contract DSCEngine {
    function depositCollateralAndMintDsc() external {}

    function depositCollateral() external {}

    function liquidate() external {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function getHealthFactor() external view {}
}
