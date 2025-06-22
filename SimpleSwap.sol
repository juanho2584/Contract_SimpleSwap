// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SimpleSwap - Decentralized Exchange Contract
/// @notice Allows adding/removing liquidity and swapping tokens
contract SimpleSwap is ReentrancyGuard {

    struct Reserves {
        uint128 reserveA;
        uint128 reserveB;
    }

    struct LiquidityData {
        uint totalSupply;
        mapping(address => uint) balance;
        Reserves reserves;
    }

    /// @dev Maps token pairs to their liquidity data
    mapping(address => mapping(address => LiquidityData)) public pairs;

    /// @notice Emitted when liquidity is added to a token pair
    /// @param tokenA The first token of the pair
    /// @param tokenB The second token of the pair
    /// @param provider The address providing liquidity
    /// @param amountA Amount of tokenA added
    /// @param amountB Amount of tokenB added
    /// @param liquidity Liquidity tokens minted
    event LiquidityAdded(
        address indexed tokenA,
        address indexed tokenB,
        address indexed provider,
        uint amountA,
        uint amountB,
        uint liquidity
    );

    /// @notice Emitted when liquidity is removed from a token pair
    /// @param tokenA The first token of the pair
    /// @param tokenB The second token of the pair
    /// @param provider The address removing liquidity
    /// @param amountA Amount of tokenA returned
    /// @param amountB Amount of tokenB returned
    /// @param liquidity Liquidity tokens burned
    event LiquidityRemoved(
        address indexed tokenA,
        address indexed tokenB,
        address indexed provider,
        uint amountA,
        uint amountB,
        uint liquidity
    );

    /// @notice Emitted when a token swap is executed
    /// @param tokenIn Token sent by the user
    /// @param tokenOut Token received by the user
    /// @param trader The address performing the swap
    /// @param amountIn Input token amount
    /// @param amountOut Output token amount
    event TokensSwapped(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed trader,
        uint amountIn,
        uint amountOut
    );

    /// @notice Adds liquidity to a token pair
    /// @dev Transfers the desired amounts to the contract and mints liquidity
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param amountADesired Desired amount of token A
    /// @param amountBDesired Desired amount of token B
    /// @param amountAMin Minimum amount of token A accepted
    /// @param amountBMin Minimum amount of token B accepted
    /// @param to Address to receive liquidity tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amountA Actual amount of token A added
    /// @return amountB Actual amount of token B added
    /// @return liquidity Liquidity tokens minted
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external nonReentrant returns (uint amountA, uint amountB, uint liquidity) {
        require(block.timestamp <= deadline, "expired");
        require(tokenA != tokenB, "identical");
        require(amountADesired > 0 && amountBDesired > 0, "invalid_amt");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        LiquidityData storage pair = pairs[tokenA][tokenB];
        uint128 reserveA = pair.reserves.reserveA;
        uint128 reserveB = pair.reserves.reserveB;

        amountA = amountADesired;
        amountB = (reserveA == 0) ? amountBDesired : (amountADesired * reserveB) / reserveA;

        require(amountA >= amountAMin && amountB >= amountBMin, "slippage");

        liquidity = (reserveA == 0) ? amountA : (amountA * pair.totalSupply) / reserveA;

        pair.reserves.reserveA += uint128(amountA);
        pair.reserves.reserveB += uint128(amountB);
        pair.totalSupply += liquidity;
        pair.balance[to] += liquidity;

        emit LiquidityAdded(tokenA, tokenB, to, amountA, amountB, liquidity);
    }

    /// @notice Removes liquidity from a token pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param liquidity Amount of liquidity tokens to burn
    /// @param amountAMin Minimum amount of token A expected
    /// @param amountBMin Minimum amount of token B expected
    /// @param to Address to receive withdrawn tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amountA Actual amount of token A returned
    /// @return amountB Actual amount of token B returned
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external nonReentrant returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "expired");
        require(liquidity > 0, "zero_liq");

        LiquidityData storage pair = pairs[tokenA][tokenB];
        require(pair.balance[msg.sender] >= liquidity, "insuff_bal");

        uint128 reserveA = pair.reserves.reserveA;
        uint128 reserveB = pair.reserves.reserveB;

        amountA = (liquidity * reserveA) / pair.totalSupply;
        amountB = (liquidity * reserveB) / pair.totalSupply;

        require(amountA >= amountAMin && amountB >= amountBMin, "slippage");

        pair.reserves.reserveA -= uint128(amountA);
        pair.reserves.reserveB -= uint128(amountB);
        pair.totalSupply -= liquidity;
        pair.balance[msg.sender] -= liquidity;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(tokenA, tokenB, msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Swaps a fixed amount of tokens for another token
    /// @param amountIn Input amount of tokenIn
    /// @param amountOutMin Minimum output amount of tokenOut
    /// @param path Array with [tokenIn, tokenOut]
    /// @param to Recipient of tokenOut
    /// @param deadline Transaction deadline
    /// @return amounts Array with [amountIn, amountOut]
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external nonReentrant returns (uint[] memory amounts) {
        require(block.timestamp <= deadline, "expired");
        require(path.length == 2, "invalid_path");
        require(amountIn > 0, "zero_input");

        address tokenIn = path[0];
        address tokenOut = path[1];

        LiquidityData storage pair = pairs[tokenIn][tokenOut];

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint amountOut = getAmountOut(amountIn, pair.reserves.reserveA, pair.reserves.reserveB);
        require(amountOut >= amountOutMin, "slippage");

        pair.reserves.reserveA += uint128(amountIn);
        pair.reserves.reserveB -= uint128(amountOut);

        IERC20(tokenOut).transfer(to, amountOut);

        amounts = new uint[](2) ;
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
    }

    /// @notice Returns the price of tokenA in terms of tokenB
    /// @param tokenA The base token
    /// @param tokenB The quote token
    /// @return price TokenA/TokenB price (scaled by 1e18)
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        Reserves memory reserves = pairs[tokenA][tokenB].reserves;
        require(reserves.reserveA > 0 && reserves.reserveB > 0, "zero_resv");
        price = (uint(reserves.reserveA) * 1e18) / reserves.reserveB;
    }

    /// @notice Calculates output amount for a given input amount and reserves
    /// @param amountIn Input token amount
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountOut Output token amount
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure returns (uint amountOut) {
        require(amountIn > 0, "zero_input");
        require(reserveIn > 0 && reserveOut > 0, "bad_resv");

        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
