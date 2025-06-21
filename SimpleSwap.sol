// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SimpleSwap - Decentralized Token Exchange and Liquidity Pool
/// @author 
/// @notice This contract allows users to add and remove liquidity, as well as swap ERC20 tokens in a decentralized manner.
/// @dev Includes reentrancy protection using ReentrancyGuard and storage optimization using uint128 types.
contract SimpleSwap is ReentrancyGuard {
    
    /// @notice Compact structure to store reserves of a token pair.
    /// @dev Uses uint128 to save storage space.
    struct Reserves {
        uint128 reserveA; ///< Reserve of token A
        uint128 reserveB; ///< Reserve of token B
    }

    /// @notice Data related to the liquidity of a token pair.
    struct LiquidityData {
        uint totalSupply; ///< Total supply of liquidity tokens issued
        mapping(address => uint) balance; ///< Liquidity token balance per user
        Reserves reserves; ///< Current reserves of the token pair
    }

    /// @notice Mapping that relates two token addresses to their liquidity data
    mapping(address => mapping(address => LiquidityData)) public pairs;

    /// @notice Emits an event when liquidity is added to a pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param provider Address of the user providing liquidity
    /// @param amountA Amount of token A provided
    /// @param amountB Amount of token B provided
    /// @param liquidity Liquidity tokens issued
    event LiquidityAdded(
        address indexed tokenA,
        address indexed tokenB,
        address indexed provider,
        uint amountA,
        uint amountB,
        uint liquidity
    );

    /// @notice Emits an event when liquidity is removed from a pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param provider Address of the user removing liquidity
    /// @param amountA Amount of token A withdrawn
    /// @param amountB Amount of token B withdrawn
    /// @param liquidity Liquidity tokens burned
    event LiquidityRemoved(
        address indexed tokenA,
        address indexed tokenB,
        address indexed provider,
        uint amountA,
        uint amountB,
        uint liquidity
    );

    /// @notice Emits an event when a token swap occurs
    /// @param tokenIn Address of the input token
    /// @param tokenOut Address of the output token
    /// @param trader Address of the user executing the swap
    /// @param amountIn Input amount
    /// @param amountOut Output amount
    event TokensSwapped(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed trader,
        uint amountIn,
        uint amountOut
    );

    /// @notice Allows a user to add liquidity to a token pair
    /// @dev On first deposit, liquidity is calculated as sqrt(x * y). Later deposits are calculated proportionally.
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param amountADesired Desired amount of token A to contribute
    /// @param amountBDesired Desired amount of token B to contribute
    /// @param amountAMin Minimum accepted amount of token A
    /// @param amountBMin Minimum accepted amount of token B
    /// @param to Address that will receive the liquidity tokens
    /// @param deadline Timestamp by which the transaction must be completed
    /// @return amountA Final contributed amount of token A
    /// @return amountB Final contributed amount of token B
    /// @return liquidity Liquidity tokens issued
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
        require(block.timestamp <= deadline, "Expired");
        require(tokenA != tokenB, "Identical tokens");
        require(amountADesired > 0 && amountBDesired > 0, "Invalid amounts");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        LiquidityData storage pair = pairs[tokenA][tokenB];

        uint128 reserveA = pair.reserves.reserveA;
        uint128 reserveB = pair.reserves.reserveB;

        if (pair.totalSupply == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
            liquidity = _sqrt(amountA * amountB);
        } else {
            uint amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Slippage B");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal >= amountAMin, "Slippage A");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
            liquidity = (amountA * pair.totalSupply) / reserveA;
        }

        require(amountA >= amountAMin && amountB >= amountBMin, "Slippage");

        pair.reserves.reserveA += uint128(amountA);
        pair.reserves.reserveB += uint128(amountB);
        pair.totalSupply += liquidity;
        pair.balance[to] += liquidity;

        emit LiquidityAdded(tokenA, tokenB, to, amountA, amountB, liquidity);
    }

    /// @notice Allows a user to remove liquidity from a token pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param liquidity Amount of liquidity tokens to burn
    /// @param amountAMin Minimum acceptable amount of token A to receive
    /// @param amountBMin Minimum acceptable amount of token B to receive
    /// @param to Address that will receive the tokens
    /// @param deadline Timestamp by which the transaction must be completed
    /// @return amountA Amount of token A withdrawn
    /// @return amountB Amount of token B withdrawn
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external nonReentrant returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "Expired");
        require(liquidity > 0, "Zero liquidity");

        LiquidityData storage pair = pairs[tokenA][tokenB];
        require(pair.balance[msg.sender] >= liquidity, "Insufficient balance");

        uint128 reserveA = pair.reserves.reserveA;
        uint128 reserveB = pair.reserves.reserveB;

        amountA = (liquidity * reserveA) / pair.totalSupply;
        amountB = (liquidity * reserveB) / pair.totalSupply;

        require(amountA >= amountAMin && amountB >= amountBMin, "Slippage");

        pair.reserves.reserveA -= uint128(amountA);
        pair.reserves.reserveB -= uint128(amountB);
        pair.totalSupply -= liquidity;
        pair.balance[msg.sender] -= liquidity;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(tokenA, tokenB, msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Executes an exact token-for-token swap
    /// @param amountIn Exact amount of input tokens
    /// @param amountOutMin Minimum acceptable amount of output tokens
    /// @param path Token route (only [tokenIn, tokenOut] allowed)
    /// @param to Address to receive output tokens
    /// @param deadline Timestamp by which the transaction must be completed
    /// @return amounts Array with input and output amounts
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external nonReentrant returns (uint[] memory amounts) {
        require(block.timestamp <= deadline, "Expired");
        require(path.length == 2, "Invalid path");
        require(amountIn > 0, "Zero input");

        address tokenIn = path[0];
        address tokenOut = path[1];
        
        LiquidityData storage pair = pairs[tokenIn][tokenOut];

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint amountOut = getAmountOut(amountIn, pair.reserves.reserveA, pair.reserves.reserveB);
        require(amountOut >= amountOutMin, "Slippage");

        pair.reserves.reserveA += uint128(amountIn);
        pair.reserves.reserveB -= uint128(amountOut);

        IERC20(tokenOut).transfer(to, amountOut);

        amounts = new uint[](2) ;
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
    }

    /// @notice Gets the current price of tokenA in terms of tokenB
    /// @dev Read-only. Price is scaled to 18 decimals.
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @return price Calculated price
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        Reserves memory reserves = pairs[tokenA][tokenB].reserves;
        require(reserves.reserveA > 0 && reserves.reserveB > 0, "Zero reserves");
        price = (uint(reserves.reserveA) * 1e18) / reserves.reserveB;
    }

    /// @notice Calculates the estimated output amount for a swap
    /// @dev Constant product formula with 0.3% fee
    /// @param amountIn Input token amount
    /// @param reserveIn Input token reserve
    /// @param reserveOut Output token reserve
    /// @return amountOut Estimated output amount
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure returns (uint amountOut) {
        require(amountIn > 0, "Zero input");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @notice Calculates the square root of a number
    /// @dev Used to compute initial pool liquidity
    /// @param x Input number
    /// @return y Square root result
    function _sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
