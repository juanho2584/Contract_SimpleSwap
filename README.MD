# 🌀 SimpleSwap

## Description

**SimpleSwap** is a smart contract written in Solidity that implements a basic decentralized exchange (DEX), inspired by Uniswap's model. It allows any user to:

- Add and remove liquidity to/from an ERC-20 token pool.
- Perform token swaps between available pairs.
- Check prices and output estimates before executing operations.

The contract is optimized for gas efficiency and protected against reentrancy attacks using OpenZeppelin's `ReentrancyGuard`.

---

## ✨ Features

- ✅ Proportional liquidity addition/removal with auto-calculation.
- 🔁 Token-to-token swaps with 0.3% fee.
- � Price calculations and output estimates (`getPrice`, `getAmountOut`).
- 🛡️ Reentrancy protection (ReentrancyGuard).
- 💾 Storage optimization using `uint128` and compact structures.
- 📊 Event logging for traceability.

---

## 🧱 Data Structures

### `Reserves`
Stores token pair reserves using `uint128` for gas savings.

```solidity
struct Reserves {
    uint128 reserveA;
    uint128 reserveB;
}
LiquidityData
Contains all pool-related information:
Current reserves.
Total liquidity tokens issued.
User liquidity token balances.

struct LiquidityData {
    uint totalSupply;
    mapping(address => uint) balance;
    Reserves reserves;
}

⚙️ Core Functionalities
addLiquidity(...)
Allows adding liquidity to a token pair.
For the first deposit: liquidity = sqrt(amountA * amountB).
Subsequent deposits are proportional to current reserves.
Returns final deposited amounts and issued liquidity tokens.

removeLiquidity(...)
Withdraws liquidity from a pair, returning original tokens proportionally.
Requires minimum acceptable returns (amountAMin, amountBMin).
Burns liquidity tokens.

swapExactTokensForTokens(...)
Swaps an exact token amount for another.
Uses constant product algorithm with 0.3% fee.
Returns actual amountOut and emits event.

getPrice(tokenA, tokenB)
Returns the price of tokenA in terms of tokenB based on current reserves.
Value uses 18 decimals.

getAmountOut(amountIn, reserveIn, reserveOut)
Calculates expected output for swapping amountIn of tokenIn.
Accounts for current reserves and applies fee.

🧮 Swap Formula
Uses constant product model with 0.3% fee:
amountInWithFee = amountIn * 997
amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee)

📦 Events
LiquidityAdded: When liquidity is added to a pool.
LiquidityRemoved: When liquidity is withdrawn.
TokensSwapped: When a token swap occurs.

🚀 Typical Workflow
Add liquidity: User deposits tokenA + tokenB, receives liquidity tokens.
Execute swap: Another user swaps tokens using the created pair.
Remove liquidity: Original user withdraws their share, reclaiming tokens + earned fees.

🔧 Requirements
Solidity ^0.8.20
OpenZeppelin:
@openzeppelin/contracts/token/ERC20/IERC20.sol
@openzeppelin/contracts/security/ReentrancyGuard.sol