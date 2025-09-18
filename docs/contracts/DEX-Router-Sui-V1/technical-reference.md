# DEX-Router-Sui Technical Reference

## Program Overview

The DEX-Router-Sui is a smart contract system that provides DEX aggregation and optimal routing capabilities on the Sui blockchain. This document provides complete technical specifications for all exported functions and data structures.

> **📝 Contract-Generated Documentation**: This technical reference is generated from Move source code analysis and interface definitions. For the most up-to-date information, refer to the source contracts.

### Main Contracts

#### Router Contract (`dexrouter`)
- **Framework**: Sui Move v1.48.2
- **Supported Protocols**: 10+ DEX integrations

#### Extended Router Contract (`dexrouter_extended`)
- **Framework**: Sui Move v1.48.2
- **Supported Protocols**: 8 DEX integrations

> **⚠️ Contract Address Updates**: These contract addresses may be updated in future versions.

## Core Data Structures

### Event Structures

#### OrderRecord
```move
struct OrderRecord has copy, drop {
    order_id: u64,      // Unique identifier for transaction tracking
    decimal: u8,        // Output token decimal precision for analytics
    out_amount: u64     // Actual output amount received
}
```

**Purpose**: Track all swap transactions with unique identifiers for external analytics and monitoring systems.

**Emission Context**: Emitted by all finalize functions to provide comprehensive transaction tracking.

#### CommissionRecord
```move
struct CommissionRecord has copy, drop {
    commission_amount: u64,   // Amount of commission collected in output tokens
    referral_address: address // Address that received the commission
}
```

**Purpose**: Monitor and audit commission distribution for referral and partner programs.

**Emission Context**: Emitted when commission rate > 0 and valid referral address provided.

#### HopRecord
```move
struct HopRecord has copy, drop {
    out_amount: u64    // Output amount for individual swap step
}
```

**Purpose**: Track individual swap steps within multi-hop routes for debugging and analytics.

**Emission Context**: Emitted by each individual protocol swap function before finalization.

### System Constants

#### Error Codes
```move
// Router Contract Error Codes
const E_ROUTER_MIN_RETURN_NOT_REACH: u64 = 1;      // Slippage protection triggered
const E_PERCENTAGE: u64 = 2;                       // Invalid percentage value
const E_COMMISSION_PERCENTAGE: u64 = 3;            // Commission rate exceeds maximum
const E_SUISWAP_MIN_RETURN_NOT_REACH: u64 = 4;     // SuiSwap slippage protection
const E_INVALID_PARAMETER: u64 = 5;                // General parameter validation
const E_AFTERMATH_INPUT_AMOUNT: u64 = 6;           // Aftermath protocol input validation
const E_KRIYA_CLMM_MIN_RETURN_NOT_REACH: u64 = 7;  // Kriya CLMM slippage protection
const E_MIN_AMOUNT_ZERO: u64 = 8;                  // Zero amount validation (main router)
const E_CETUS_MIN_RETURN_NOT_REACH: u64 = 9;       // Cetus protocol slippage protection
const E_KRIYA_CLMM_INPUT_AMOUNT: u64 = 10;         // Kriya CLMM input validation

// Extended Router Error Codes
const E_MIN_AMOUNT_ZERO: u64 = 6;                  // Zero amount validation (extended router)
const E_SLIPPAGE_EXCEEDED: u64 = 7;                // Extended router slippage protection
const E_INPUT_AMOUNT: u64 = 8;                     // Extended router input validation
```

## Supported DEX Protocols

### Router Contract Protocols (13 Total)

#### Concentrated Liquidity Market Makers (CLMM)
```move
// Cetus CLMM - Advanced concentrated liquidity
cetus_swap_a2b_with_return<CoinTypeA, CoinTypeB>    // A-to-B swap
cetus_swap_b2a_with_return<CoinTypeA, CoinTypeB>    // B-to-A swap

// Turbos CLMM - High-performance concentrated liquidity  
turbos_swap_a_b_with_return<CoinTypeA, CoinTypeB, FeeType>  // A-to-B swap

// Kriya CLMM - Dual protocol concentrated liquidity
kriya_clmm_swap_token_x_with_return<T0, T1>        // Token X swap
kriya_clmm_swap_token_y_with_return<T0, T1>        // Token Y swap

// FlowX v3 - Next-generation CLMM
flowxv3_swap_a2b_with_return<CoinTypeA, CoinTypeB> // A-to-B swap
flowxv3_swap_b2a_with_return<CoinTypeA, CoinTypeB> // B-to-A swap
```

#### Automated Market Makers (AMM)
```move
// SuiSwap - Native Sui AMM
suiswap_x_2_y_with_return<Ty0, Ty1>                // X-to-Y swap
suiswap_y_2_x_with_return<Ty0, Ty1>                // Y-to-X swap

// Kriya AMM - Traditional AMM
kriya_amm_swap_token_x_with_return<T0, T1>         // Token X swap
kriya_amm_swap_token_y_with_return<T0, T1>         // Token Y swap

// FlowX v2 - Direct swap
flowx_swap_exact_input_direct_with_return<CoinTypeA, CoinTypeB>

// Aftermath - Advanced AMM with insurance
aftermath_swap_exact_in_with_return<T0, T1, T2>
```

#### Order Book Systems
```move
// DeepBook V3 - Central limit order book
deepbook_swap_base_to_quote_with_return<BaseAsset, QuoteAsset>
deepbook_swap_quote_to_base_with_return<BaseAsset, QuoteAsset>
```

#### Liquid Staking Protocols
```move
// AFSUI - Aftermath Finance liquid staking
afsui_swap_a2b_with_return                         // SUI → AFSUI staking
afsui_swap_b2a_with_return                         // AFSUI → SUI unstaking
```

## Public Functions

### Core Router Functions

#### finalize
```move
public fun finalize<CoinType>(
    coin: Coin<CoinType>,
    min_amount: u64,
    toCommissionRate: u64,
    referalAddress: address,
    swapReceiverAddress: address,
    order_id: u64,
    decimal: u8,
    ctx: &mut TxContext,
)
```

**Purpose**: Complete swap transaction with commission processing and final validation.

**Parameters**:
- `coin` | `Coin<CoinType>` | Output coin from swap operation
- `min_amount` | `u64` | Minimum acceptable output amount (slippage protection)
- `toCommissionRate` | `u64` | Commission rate in basis points (0-300)
- `referalAddress` | `address` | Address to receive commission (must be non-zero if commission > 0)
- `swapReceiverAddress` | `address` | Final recipient address (sender if @0x0)
- `order_id` | `u64` | Unique identifier for transaction tracking
- `decimal` | `u8` | Token decimal precision for proper event emission
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: None (transfers coins to appropriate recipients)

**Access Control**: Public function, no restrictions

**Error Conditions**:
- `E_MIN_AMOUNT_ZERO`: Minimum amount must be greater than zero
- `E_ROUTER_MIN_RETURN_NOT_REACH`: Output amount below minimum threshold
- `E_INVALID_PARAMETER`: Commission rate without valid referral address

### Commission Management Functions

#### split_with_percentage
```move
public fun split_with_percentage<T>(
    coin: &mut Coin<T>,
    percentage: u64,
    ctx: &mut TxContext
): (Coin<T>, u64, Coin<T>, u64)
```

**Purpose**: Split coin into two parts based on percentage allocation.

**Parameters**:
- `coin` | `&mut Coin<T>` | Source coin to split (modified in place)
- `percentage` | `u64` | Percentage in basis points (0-10000)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<T>, u64, Coin<T>, u64)` - Split coin with amount, remaining coin with amount

**Error Conditions**:
- `E_PERCENTAGE`: Percentage exceeds maximum allowed value (10000)

#### split_with_percentage_for_commission
```move
public fun split_with_percentage_for_commission<T>(
    coin: &mut Coin<T>,
    commissionRate: u64,
    referalAddress: address,
    ctx: &mut TxContext
): (Coin<T>, u64)
```

**Purpose**: Split coin for commission payment with automatic transfer to referral address.

**Parameters**:
- `coin` | `&mut Coin<T>` | Source coin to split for commission
- `commissionRate` | `u64` | Commission rate in basis points (0-300)
- `referalAddress` | `address` | Address to receive commission payment
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<T>, u64)` - Remaining coin after commission and its amount

**Error Conditions**:
- `E_COMMISSION_PERCENTAGE`: Commission rate exceeds 3% maximum
- `E_INVALID_PARAMETER`: Non-zero commission without valid referral address

**Parameters**:
- `coin` | `Coin<CoinType>` | Output coin from swap operation
- `order_id` | `u64` | Unique identifier for transaction tracking
- `decimal` | `u8` | Token decimal precision for proper event emission
- `_ctx` | `&mut TxContext` | Transaction context (unused)

**Returns**: `(Coin<CoinType>, u64)` - Original coin and its amount for chaining

**Access Control**: Public function, no restrictions

**Error Conditions**: None

## Events Reference

### OrderRecord Event
**Emitted By**: All `finalize` functions
**Purpose**: Track completed transactions for analytics and monitoring
**Fields**:
- `order_id`: Unique transaction identifier for external tracking systems
- `decimal`: Token decimal precision for proper amount interpretation
- `out_amount`: Final output amount received by user

**Usage Example**:
```move
event::emit(OrderRecord{ 
    order_id: 12345,
    decimal: 6,  // USDC has 6 decimals
    out_amount: 1000000  // 1 USDC
});
```

### CommissionRecord Event
**Emitted By**: `split_with_percentage_for_commission` and `finalize` (when commission > 0)
**Purpose**: Audit trail for commission payments and partner revenue tracking
**Fields**:
- `commission_amount`: Amount of commission paid in output tokens
- `referral_address`: Address that received the commission payment

**Usage Example**:
```move
event::emit(CommissionRecord{ 
    commission_amount: 10000,  // 0.01 USDC commission
    referral_address: @0x123...
});
```

### HopRecord Event
**Emitted By**: Individual protocol swap functions
**Purpose**: Track intermediate steps in multi-hop routes for debugging and optimization
**Fields**:
- `out_amount`: Output amount from individual swap step

**Usage Example**:
```move
event::emit(HopRecord{
    out_amount: 500000  // 0.5 USDC from this hop
});
```

## Error Reference

### Custom Error Definitions

#### E_ROUTER_MIN_RETURN_NOT_REACH (1)
**Description**: Output amount is below the specified minimum threshold
**Triggered By**: `finalize` function when `amount_out < min_amount`
**Common Causes**: 
- High slippage in volatile market conditions
- Insufficient liquidity in the pool
- Incorrect minimum amount calculation

**Resolution**: Increase slippage tolerance or verify pool liquidity

#### E_COMMISSION_PERCENTAGE (3)
**Description**: Commission rate exceeds the maximum allowed 3%
**Triggered By**: Commission functions when `commissionRate > MAX_COMMISSION_RATE`
**Common Causes**: Incorrect commission rate calculation (using percentages instead of basis points)
**Resolution**: Use basis points (300 = 3%, 100 = 1%, etc.)

#### E_INVALID_PARAMETER (5)
**Description**: Invalid parameter combination detected
**Triggered By**: Functions when commission rate > 0 but referral address is @0x0
**Common Causes**: Setting commission without providing valid referral address
**Resolution**: Provide valid referral address or set commission rate to 0

#### E_MIN_AMOUNT_ZERO (Main Router: 8, Extended Router: 6)
**Description**: Minimum amount parameter cannot be zero
**Triggered By**: `finalize` function when `min_amount == 0`
**Common Causes**: Incorrect parameter validation in calling code
**Resolution**: Set appropriate minimum amount for slippage protection

### Protocol-Specific Errors

#### E_CETUS_MIN_RETURN_NOT_REACH (9)
**Description**: Cetus swap output below minimum threshold
**Specific To**: Cetus CLMM protocol integration
**Resolution**: Adjust slippage parameters for Cetus-specific conditions

#### E_KRIYA_CLMM_MIN_RETURN_NOT_REACH (7)
**Description**: Kriya CLMM swap output below minimum threshold  
**Specific To**: Kriya CLMM protocol integration
**Resolution**: Verify Kriya pool liquidity and adjust minimum output

#### E_SLIPPAGE_EXCEEDED (7) - Extended Router
**Description**: Extended router slippage protection triggered
**Specific To**: Protocols in extended router
**Resolution**: Review slippage settings for experimental protocols

## Constants and Configuration

### System Constants
```move
pub const MAX_COMMISSION_RATE: u64 = 300;        // 3% maximum commission
pub const MAX_PERCENTAGE: u64 = 10000;           // 100% in basis points
pub const PERCENTAGE_DIVISOR: u64 = 10000;       // Basis point divisor
```

### Commission Configuration
```move
pub const COMMISSION_RATE_LIMIT: u64 = 300;      // 3% maximum (300 basis points)
pub const COMMISSION_DENOMINATOR: u64 = 10000;   // 100% (10000 basis points)
```

### Fee Structures

#### Commission Calculation
- **Input-based Commission**: `commission = amount_in * rate / (denominator - rate)`
- **Output-based Commission**: `commission = amount_out * rate / denominator`

#### Basis Points System
- **1%**: 100 basis points
- **3%**: 300 basis points (maximum allowed)
- **100%**: 10000 basis points

### Gas Budget Recommendations
```move
pub const BASIC_SWAP_GAS: u64 = 4051120;         // Basic single protocol swap
pub const COMPLEX_ROUTING_GAS: u64 = 10000000;   // Multi-protocol routing
pub const COMMISSION_SWAP_GAS: u64 = 6000000;    // Swap with commission
```

## Advanced Features

### Multi-Protocol Routing
The DEX Router supports complex routing strategies across multiple protocols:

- **Sequential Routing**: Execute swaps in sequence across different protocols
- **Parallel Routing**: Split orders across multiple protocols simultaneously  
- **Percentage-based Splitting**: Distribute trades based on configurable percentages

### Commission System
Comprehensive commission management for partner integrations:

- **Flexible Rates**: Configurable commission rates up to 3%
- **Basis Points**: Precise rate control using basis point system
- **Automatic Distribution**: Real-time commission transfer to referral addresses

### Event System
Comprehensive event emission for analytics and monitoring:

- **Transaction Tracking**: Unique order IDs for all operations
- **Commission Auditing**: Detailed commission payment records
- **Hop Tracking**: Individual swap step monitoring for multi-hop routes

## Security Considerations

### Access Control
- All functions are public with appropriate parameter validation
- Commission recipients must be valid addresses
- Transaction context validation prevents unauthorized operations

### Numerical Safety
- All arithmetic operations use safe math with overflow protection
- Precision maintained for token operations with proper decimal handling
- Commission calculations include bounds checking
- Rate limits prevent excessive fees

### Parameter Validation
- Commission rates capped at reasonable maximums (3%)
- Percentage values validated within acceptable ranges (0-10000 basis points)
- Minimum amounts must be greater than zero
- Address validation for commission recipients

### Error Handling
- Comprehensive error codes for all failure scenarios
- Protocol-specific error handling for different DEX integrations

## Integration Guide

### Basic Integration
1. **Simple Swap**: Use protocol-specific swap functions for single DEX integration
2. **Commission Integration**: Use `split_with_percentage_for_commission` for fee collection
3. **Finalization**: Always call `finalize` to complete transactions properly

### Advanced Integration
1. **Multi-Protocol Routing**: Combine multiple swap functions for optimal execution
2. **Commission Management**: Implement comprehensive fee collection strategies
3. **Event Monitoring**: Subscribe to events for real-time analytics and monitoring

### Best Practices
1. **Gas Management**: Set appropriate gas budgets based on operation complexity
2. **Slippage Control**: Implement reasonable slippage tolerances for market conditions
3. **Error Handling**: Implement comprehensive error handling for all scenarios
4. **Testing**: Thoroughly test all integration points with various market conditions
5. **Monitoring**: Implement proper monitoring and alerting for production deployments