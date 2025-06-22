🌀 SimpleSwap - Detailed Explanation

Overview:
----------
SimpleSwap is a decentralized exchange (DEX) smart contract implemented in Solidity. Inspired by the core mechanics of Uniswap, it allows users to:

1. Add liquidity to a pool of two ERC-20 tokens.
2. Remove liquidity from an existing pool.
3. Swap tokens between pairs with an automatic pricing mechanism.
4. Query token prices and expected swap outputs.

Core Concepts:
--------------

1. Liquidity Pools:
   - Each token pair (tokenA, tokenB) is associated with a 'LiquidityData' structure.
   - This structure contains:
     • totalSupply: Total amount of liquidity tokens issued.
     • balance: Mapping of user addresses to their liquidity balance.
     • reserves: Contains current token reserves (reserveA and reserveB).

2. Events:
   - LiquidityAdded: Emitted when a user provides liquidity to a pool.
   - LiquidityRemoved: Emitted when a user withdraws liquidity.
   - TokensSwapped: Emitted when a swap is successfully executed.

Functions:
----------

1. addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline)
   - Allows a user to provide liquidity to a token pair.
   - Calculates optimal token proportions and ensures slippage protection.
   - Mints and assigns liquidity tokens to the 'to' address.

2. removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline)
   - Allows a user to withdraw their share of the liquidity pool.
   - Burns the caller’s liquidity tokens and returns tokenA and tokenB.
   - Enforces slippage protection and deadline.

3. swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline)
   - Swaps an exact amount of input tokens for another token.
   - Only supports two-token path (i.e., a single token pair).
   - Uses the constant product formula for price calculation.
   - Transfers output tokens to the 'to' address.

4. getPrice(tokenA, tokenB)
   - Returns the current price of tokenA denominated in tokenB.
   - Result is scaled by 1e18 to support decimals.

5. getAmountOut(amountIn, reserveIn, reserveOut)
   - Pure function used internally and externally to calculate the output amount of a swap based on constant product formula.
   - Ensures input and reserve values are valid.

Error Handling (Shortstrings):
------------------------------
For gas efficiency, error messages are shortened:
  - "expired" — Operation attempted after deadline.
  - "identical" — tokenA and tokenB are the same.
  - "invalid_amt" — One or both desired amounts are zero.
  - "slippage" — Output/input does not meet minimum requirements.
  - "zero_liq" — Liquidity provided is zero.
  - "insuff_bal" — User lacks sufficient liquidity balance.
  - "invalid_path" — Swap path is not exactly two tokens.
  - "zero_input" — Input amount is zero.
  - "zero_resv"/"bad_resv" — Reserves are invalid or zero.

Security:
---------
- Uses OpenZeppelin's ReentrancyGuard to prevent reentrancy attacks on liquidity and swap operations.
- Input validation is performed for deadlines, amount values, and reserve checks.

