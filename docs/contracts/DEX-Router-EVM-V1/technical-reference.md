# DEX-Router-EVM Technical Reference

## Contract Overview

The DEX-Router-EVM is a sophisticated smart contract system that provides DEX aggregation and optimal routing capabilities. This document provides complete technical specifications for all exported interfaces and functions.

> **📝 Auto-Generated Documentation**: This technical reference is automatically generated from Solidity NatSpec comments in the source code using `solidity-docgen`. For the most up-to-date information, refer to the source contracts.

### Main Contract
- **Name**: DexRouter
- **Version**: v1.0.4-toB-commission
- **Solidity Version**: 0.8.17
- **License**: MIT

### ExactOut Router System
- **Name**: DexRouterExactOut
- **Version**: v1.0.1
- **Solidity Version**: 0.8.17
- **License**: MIT

## Core Interfaces

### BaseRequest Structure
```solidity
struct BaseRequest {
    uint256 fromToken;        // Source token (address encoded as uint256)
    address toToken;          // Destination token address
    uint256 fromTokenAmount;  // Amount of source token to swap
    uint256 minReturnAmount;  // Minimum amount of destination token to receive
    uint256 deadLine;         // UNIX timestamp deadLine for the swap
}
```

### RouterPath Structure
```solidity
struct RouterPath {
    address[] mixAdapters;    // Array of adapter contract addresses
    address[] assetTo;        // Array of intermediate token addresses
    uint256[] rawData;        // Array of encoded routing data
    bytes[] extraData;        // Array of additional data for adapters
    uint256 fromToken;        // Source token (address encoded as uint256)
}
```

## ExactOut Router System

### Overview
The ExactOut router system provides specialized functionality for exact output swaps, where users specify the exact amount of output tokens they want to receive and set a maximum limit on input tokens they're willing to spend. Unlike the standard router, ExactOut works directly with pools without using the adapter layer for maximum efficiency.

### Key Concepts

#### Exact Output vs Exact Input
- **Exact Input**: "I want to swap exactly 1000 USDC for as much ETH as possible"
- **Exact Output**: "I want to receive exactly 1 ETH and will pay up to 3000 USDC"

#### Benefits of Exact Output
- **Predictable Outcomes**: Know exactly how much you'll receive
- **Cost Control**: Set maximum spending limits
- **Gas Efficiency**: Direct pool interaction without adapter overhead
- **DeFi Integration**: Perfect for protocols that need exact amounts

### DexRouterExactOut Contract

#### Core Functions

##### `unxswapExactOutTo`
Executes an exact output swap using the Unxswap protocol.

```solidity
function unxswapExactOutTo(
    uint256 srcToken,
    uint256 amount,
    uint256 maxConsume,
    address receiver,
    bytes32[] calldata pools
) external payable returns (uint256 consumeAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token address encoded with order ID mask
- `amount` (uint256): Exact amount of output tokens to receive
- `maxConsume` (uint256): Maximum amount of input tokens to spend
- `receiver` (address): Address to receive the output tokens
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `consumeAmount` (uint256): Actual amount of input tokens consumed

**Features:**
- Automatic order ID extraction and emission
- Commission handling integrated
- Slippage protection via `maxConsume`
- Support for ETH and ERC20 tokens

##### `unxswapExactOutToByOrderID`
Executes an exact output swap where the receiver is the sender.

```solidity
function unxswapExactOutToByOrderID(
    uint256 srcToken,
    uint256 amount,
    uint256 maxConsume,
    bytes32[] calldata pools
) external payable returns (uint256 consumeAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token address encoded with order ID mask
- `amount` (uint256): Exact amount of output tokens to receive
- `maxConsume` (uint256): Maximum amount of input tokens to spend
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `consumeAmount` (uint256): Actual amount of input tokens consumed

**Features:**
- Simplified interface for self-receiving swaps
- Automatic order ID handling
- Commission integration

##### `uniswapV3SwapExactOutTo`
Executes an exact output swap using Uniswap V3 protocol.

```solidity
function uniswapV3SwapExactOutTo(
    uint256 receiver,
    uint256 amountOut,
    uint256 maxConsume,
    uint256[] calldata pools
) external payable returns (uint256 consumeAmount)
```

**Parameters:**
- `receiver` (uint256): Receiver address encoded with order ID
- `amountOut` (uint256): Exact amount of output tokens to receive
- `maxConsume` (uint256): Maximum amount of input tokens to spend
- `pools` (uint256[]): Array of V3 pool identifiers

**Returns:**
- `consumeAmount` (uint256): Actual amount of input tokens consumed

**Features:**
- Uniswap V3 concentrated liquidity support
- Automatic ETH/WETH handling
- Commission processing
- Multi-hop routing support

### UnxswapExactOutRouter Contract

#### Core Internal Function

##### `_unxswapExactOutInternal`
Core internal function for executing exact output swaps on Uniswap V2-style pools.

```solidity
function _unxswapExactOutInternal(
    IERC20 srcToken,
    uint256 amount,
    uint256 maxConsume,
    bytes32[] calldata pools,
    address payer,
    address receiver
) internal returns (uint256 returnAmount)
```

**Parameters:**
- `srcToken` (IERC20): Source token contract
- `amount` (uint256): Exact amount of output tokens desired
- `maxConsume` (uint256): Maximum input tokens to spend
- `pools` (bytes32[]): Pool routing path
- `payer` (address): Address providing input tokens
- `receiver` (address): Address receiving output tokens

**Returns:**
- `returnAmount` (uint256): Actual amount of input tokens consumed

**Algorithm:**
1. **Backwards Calculation**: Calculate required input for each pool in reverse order
2. **Input Validation**: Ensure required input doesn't exceed `maxConsume`
3. **Token Transfer**: Handle input token transfer from payer to first pool
4. **Swap Execution**: Execute swaps in forward order
5. **ETH Handling**: Unwrap WETH to ETH if needed for final output

#### Key Features

##### Reverse Path Calculation
The system calculates the required input amount by working backwards from the desired output:

```solidity
// Calculate required input for each pool, working backwards
for(uint i = pools.length; i > 0; i--) {
    bytes32 poolData = pools[i-1];
    amounts[i-1] = _calculateRequiredInputAmount(poolData, amounts[i]);
}
```

##### Input Amount Validation
Protects users from excessive input consumption:

```solidity
require(returnAmount <= maxConsume, "excessive input amount");
```

##### ETH/WETH Handling
Automatic conversion between ETH and WETH when needed:

```solidity
if(isWeth) {
    IWETH(_WETH).withdraw(amountOut);
    (bool success,) = receiver.call{value: amountOut}("");
    require(success, "ETH transfer failed");
}
```

### UnxswapV3ExactOutRouter Contract

#### Core Functions

##### `_uniswapV3SwapExactOut`
Executes exact output swaps on Uniswap V3 pools.

```solidity
function _uniswapV3SwapExactOut(
    address payer,
    address payable receiver,
    uint256 amountOut,
    uint256 maxConsume,
    uint256[] calldata pools
) internal returns (uint256 consumedAmount)
```

**Parameters:**
- `payer` (address): Address providing input tokens
- `receiver` (address): Address receiving output tokens
- `amountOut` (uint256): Exact amount of output tokens desired
- `maxConsume` (uint256): Maximum input tokens to spend
- `pools` (uint256[]): V3 pool routing path

**Returns:**
- `consumedAmount` (uint256): Actual amount of input tokens consumed

**Features:**
- Recursive swap execution
- Automatic WETH unwrapping
- Input amount tracking
- Slippage protection

##### `_executeSwapRecursive`
Recursively executes swaps through multiple V3 pools.

```solidity
function _executeSwapRecursive(
    address payer,
    address receiver,
    uint256 amountOut,
    uint256[] memory pools
) private returns (int256 amount0, int256 amount1)
```

**Parameters:**
- `payer` (address): Address providing tokens
- `receiver` (address): Address receiving tokens
- `amountOut` (uint256): Desired output amount
- `pools` (uint256[]): Remaining pools in path

**Returns:**
- `amount0` (int256): Change in token0 balance
- `amount1` (int256): Change in token1 balance

**Algorithm:**
1. **Pool Extraction**: Extract pool address and swap direction
2. **Callback Data**: Prepare data for swap callback
3. **Recursive Execution**: Handle remaining pools in path
4. **Swap Execution**: Execute the actual V3 swap

##### `uniswapV3SwapCallback`
Handles Uniswap V3 swap callbacks for exact output swaps.

```solidity
function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
) external override
```

**Parameters:**
- `amount0Delta` (int256): Change in token0 balance
- `amount1Delta` (int256): Change in token1 balance
- `data` (bytes): Callback data containing payer and remaining pools

**Features:**
- Pool validation for security
- Recursive swap handling
- Token payment processing
- Amount tracking

### Usage Patterns

#### Basic Exact Output Swap
```solidity
// Swap to receive exactly 1 ETH, spending up to 3000 USDC
uint256 consumed = dexRouterExactOut.unxswapExactOutTo(
    uint256(uint160(usdcAddress)) | orderId,  // Source token with order ID
    1 ether,                                  // Exact output amount
    3000 * 1e6,                              // Maximum input amount
    msg.sender,                               // Receiver
    pools                                     // Routing pools
);
```

#### Uniswap V3 Exact Output
```solidity
// V3 exact output swap
uint256 consumed = dexRouterExactOut.uniswapV3SwapExactOutTo(
    uint256(uint160(msg.sender)) | orderId,  // Receiver with order ID
    1 ether,                                  // Exact output amount
    3000 * 1e6,                              // Maximum input amount
    v3Pools                                   // V3 routing pools
);
```

#### Commission Integration
```solidity
// Exact output swap with commission
bytes memory swapData = abi.encodeWithSelector(
    dexRouterExactOut.unxswapExactOutTo.selector,
    srcToken,
    amount,
    maxConsume,
    receiver,
    pools
);

bytes memory data = bytes.concat(
    swapData,
    _getCommissionInfo(true, true, false, outputToken)
);

(bool success, bytes memory result) = address(dexRouterExactOut).call(data);
```

### Security Considerations

#### Input Validation
- Maximum consumption limits prevent excessive spending
- Pool validation ensures legitimate Uniswap pools
- Address validation prevents zero address issues

#### Slippage Protection
- `maxConsume` parameter provides cost protection
- Automatic calculation prevents unfavorable swaps
- DeadLine enforcement prevents stale transactions

#### Reentrancy Protection
- Inherited from base contracts
- Secure external calls
- State updates before external interactions

### Gas Optimization

#### Recursive Execution
- Efficient callback handling
- Minimal state storage
- Optimized pool interactions

#### Memory Management
- Efficient array handling
- Minimal storage operations
- Optimized data structures

## Public Functions

### Smart Swap Functions

#### `smartSwapByOrderId`
Executes a smart swap based on the given order ID, supporting complex multi-path swaps.

```solidity
function smartSwapByOrderId(
    uint256 orderId,
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `orderId` (uint256): Unique identifier for the swap order
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Modifiers:**
- `payable`: Can receive ETH for ETH swaps
- `isExpired(baseRequest.deadLine)`: Validates deadLine

**Events:**
- `SwapOrderId(orderId)`: Emitted when swap starts
- `OrderRecord(fromToken, toToken, origin, fromAmount, returnAmount)`: Emitted when swap completes

#### `smartSwapTo`
Executes a smart swap directly to a specified receiver address.

```solidity
function smartSwapTo(
    uint256 orderId,
    address receiver,
    BaseRequest calldata baseRequest,
    uint256[] calldata batchesAmount,
    RouterPath[][] calldata batches,
    PMMLib.PMMSwapRequest[] calldata extraData
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `orderId` (uint256): Unique identifier for the swap order
- `receiver` (address): Address to receive the output tokens
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Requirements:**
- `receiver` must not be address(0)
- DeadLine must not be expired

#### `smartSwapByInvest`
Executes a swap tailored for pre-funded scenarios, adjusting swap amounts based on the contract's balance.

```solidity
function smartSwapByInvest(
    BaseRequest memory baseRequest,
    uint256[] memory batchesAmount,
    RouterPath[][] memory batches,
    PMMLib.PMMSwapRequest[] memory extraData,
    address to
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data
- `to` (address): Address where swapped tokens will be sent

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Special Features:**
- Automatically adjusts batch amounts based on contract balance
- Designed for pre-funded contract integration

#### `smartSwapByInvestWithRefund`
Enhanced pre-funded swap with separate refund address.

```solidity
function smartSwapByInvestWithRefund(
    BaseRequest memory baseRequest,
    uint256[] memory batchesAmount,
    RouterPath[][] memory batches,
    PMMLib.PMMSwapRequest[] memory extraData,
    address to,
    address refundTo
) public payable returns (uint256 returnAmount)
```

**Parameters:**
- `baseRequest` (BaseRequest): Base parameters for the swap
- `batchesAmount` (uint256[]): Array of amounts for each batch
- `batches` (RouterPath[][]): Array of routing paths for each batch
- `extraData` (PMMLib.PMMSwapRequest[]): Additional PMM swap data
- `to` (address): Address where swapped tokens will be sent
- `refundTo` (address): Address for refunding unused tokens

**Returns:**
- `returnAmount` (uint256): Total amount of destination tokens received

**Requirements:**
- `fromToken` must not be ETH (address(0))
- `refundTo` must not be address(0)
- `to` must not be address(0)
- `fromTokenAmount` must be greater than 0

### Unxswap Functions

#### `unxswapByOrderId`
Executes a token swap using the Unxswap protocol based on a specified order ID.

```solidity
function unxswapByOrderId(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    bytes32[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token (address encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens expected to receive
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `returnAmount` (uint256): Amount of destination tokens received

**Features:**
- Automatically extracts order ID from `srcToken` parameter
- Optimized for Uniswap V2-style pools

#### `unxswapTo`
Executes a token swap using the Unxswap protocol, sending output to a specified receiver.

```solidity
function unxswapTo(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    address receiver,
    bytes32[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token (address encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens expected to receive
- `receiver` (address): Address to receive the output tokens
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `returnAmount` (uint256): Amount of destination tokens received

**Requirements:**
- `receiver` must not be address(0)

### Uniswap V3 Functions

#### `uniswapV3SwapTo`
Executes a swap using the Uniswap V3 protocol.

```solidity
function uniswapV3SwapTo(
    uint256 receiver,
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `receiver` (uint256): Receiver address (encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens to receive
- `pools` (uint256[]): Array of pool identifiers for V3 routing

**Returns:**
- `returnAmount` (uint256): Amount of tokens received after swap

**Features:**
- Handles ETH/WETH wrapping automatically
- Supports complex multi-hop V3 routes
- Integrated commission handling
- **Gas-efficient**: Optimized for Uniswap V3 concentrated liquidity pools
- **Direct pool interaction**: Bypasses adapters for better gas efficiency

## Gas-Efficient Swap Functions

### Unxswap Functions (Uniswap V2-like)

#### `unxswapByOrderId`
Executes a gas-efficient token swap using Uniswap V2-like pools.

```solidity
function unxswapByOrderId(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    bytes32[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token (address encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens expected to receive
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `returnAmount` (uint256): Amount of destination tokens received

**Features:**
- **Gas-optimized**: Direct pool interactions without adapter overhead
- **Multi-hop support**: Efficient routing through multiple V2-like pools
- **Order ID tracking**: Automatic order ID extraction and emission
- **Commission handling**: Built-in fee collection system

#### `unxswapTo`
Executes a gas-efficient swap with custom receiver address.

```solidity
function unxswapTo(
    uint256 srcToken,
    uint256 amount,
    uint256 minReturn,
    address receiver,
    bytes32[] calldata pools
) external payable returns (uint256 returnAmount)
```

**Parameters:**
- `srcToken` (uint256): Source token (address encoded with order ID)
- `amount` (uint256): Amount of source token to swap
- `minReturn` (uint256): Minimum amount of tokens expected to receive
- `receiver` (address): Address to receive the output tokens
- `pools` (bytes32[]): Array of pool identifiers for routing

**Returns:**
- `returnAmount` (uint256): Amount of destination tokens received

**Features:**
- **Flexible receiver**: Send tokens to any address
- **Gas-efficient**: Optimized for V2-like pool interactions
- **Multi-path routing**: Support for complex swap paths

## Events

### `SwapOrderId`
Emitted when a swap operation starts.

```solidity
event SwapOrderId(uint256 orderId);
```

**Parameters:**
- `orderId` (uint256): Unique identifier for the swap

### `OrderRecord`
Emitted when a swap operation completes.

```solidity
event OrderRecord(
    address indexed fromToken,
    address indexed toToken,
    address indexed origin,
    uint256 fromAmount,
    uint256 returnAmount
);
```

**Parameters:**
- `fromToken` (address): Source token address
- `toToken` (address): Destination token address
- `origin` (address): Transaction origin address
- `fromAmount` (uint256): Amount of source token
- `returnAmount` (uint256): Amount of destination token received

## Error Codes

### Common Errors
- `"Route: expired"`: Swap deadLine has passed
- `"Route: fromTokenAmount must be > 0"`: Invalid input amount
- `"Route: number of batches should be <= fromTokenAmount"`: Invalid batch configuration
- `"length mismatch"`: Array length mismatch
- `"Min return not reached"`: Insufficient output amount
- `"not addr(0)"`: Invalid zero address
- `"totalWeight can not exceed 10000 limit"`: Invalid weight configuration
- `"transfer native token failed"`: ETH transfer failed

### Pre-funded Swap Specific Errors
- `"Invalid source token"`: ETH not allowed for pre-funded swaps
- `"refundTo is address(0)"`: Invalid refund address
- `"to is address(0)"`: Invalid recipient address
- `"fromTokenAmount is 0"`: Invalid input amount

## Constants

### Address Masks
```solidity
uint256 private constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
uint256 private constant _REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
uint256 private constant _WEIGHT_MASK = 0x00000000000000000000000000000000000000000000000000000000ffffffff;
uint256 private constant _ORDER_ID_MASK = 0x0000000000000000000000000000000000000000000000000000000000000000;
uint256 private constant _ONE_FOR_ZERO_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
```

### System Constants
```solidity
uint256 private constant _DENOMINATOR = 1_000_000_000;
uint256 private constant _NUMERATOR_OFFSET = 160;
address private constant _ETH = address(0);
```
