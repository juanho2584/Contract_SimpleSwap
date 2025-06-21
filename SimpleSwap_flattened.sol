
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: Contratos_2025/Swap/SimpleSwap.sol


pragma solidity ^0.8.20;



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
