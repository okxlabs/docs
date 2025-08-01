# DEX Router - Technical Reference

**Auto-generated from Move code annotations and interface analysis**

## Program Overview

### Router Contract (`dexrouter`)

- **Framework**: Sui Move Framework v1.48.2
- **License**: Licensed under standard Move package licensing
- **Purpose**: Production-grade DEX aggregation router for Sui blockchain with 14 protocol integrations

### Extended Router Contract (`dexrouter_extended`)

- **Framework**: Sui Move Framework v1.48.2
- **License**: Licensed under standard Move package licensing
- **Purpose**: DeFi protocol integration router with 8+ experimental protocols

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

**Usage Context**: Emitted by all finalize functions to provide comprehensive transaction tracking.

#### CommissionRecord
```move
struct CommissionRecord has copy, drop {
    commission_amount: u64,   // Amount of commission collected in output tokens
    referral_address: address // Address that received the commission
}
```

**Purpose**: Monitor and audit commission distribution for referral and partner programs.

**Usage Context**: Emitted when commission rate > 0 and valid referral address provided.

#### HopRecord
```move
struct HopRecord has copy, drop {
    out_amount: u64    // Output amount for individual swap step
}
```

**Purpose**: Track individual swap steps within multi-hop routes for debugging and analytics.

**Usage Context**: Emitted by each individual protocol swap function before finalization.

### System Constants

#### Commission Configuration
```move
const MAX_COMMISSION_RATE: u64 = 300;    // 3% maximum (300 basis points)
const MAX_PERCENTAGE: u64 = 10000;       // 100% in basis points
const PERCENTAGE_DIVISOR: u64 = 10000;   // Basis point calculation divisor
```

#### Error Codes
```move
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

// Extended Router Error Codes (different values)
const E_MIN_AMOUNT_ZERO: u64 = 6;                  // Zero amount validation (extended router)
const E_SLIPPAGE_EXCEEDED: u64 = 7;                // Extended router slippage protection
const E_INPUT_AMOUNT: u64 = 8;                     // Extended router input validation
```


## API Reference by Category

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

#### finalize_without_transfer
```move
public fun finalize_without_transfer<CoinType>(
    coin: Coin<CoinType>,
    order_id: u64,
    decimal: u8,
    _ctx: &mut TxContext,
): (Coin<CoinType>, u64)
```

**Purpose**: Complete swap transaction without transferring coins, returns coins for further processing.

**Parameters**:
- `coin` | `Coin<CoinType>` | Output coin from swap operation
- `order_id` | `u64` | Unique identifier for transaction tracking
- `decimal` | `u8` | Token decimal precision for proper event emission
- `_ctx` | `&mut TxContext` | Transaction context (unused)

**Returns**: `(Coin<CoinType>, u64)` - Original coin and its amount for chaining

**Access Control**: Public function, no restrictions

**Error Conditions**: None

### Core DEX Protocol Integrations (Router)

#### Cetus CLMM Integration

##### cetus_swap_a2b_with_return
```move
public fun cetus_swap_a2b_with_return<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coins_a: vector<Coin<CoinTypeA>>,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<CoinTypeB>, u64)
```

**Purpose**: Execute A-to-B swap through Cetus concentrated liquidity protocol.

**Parameters**:
- `config` | `&GlobalConfig` | Cetus global configuration object
- `pool` | `&mut Pool<CoinTypeA, CoinTypeB>` | Cetus pool for the trading pair
- `coins_a` | `vector<Coin<CoinTypeA>>` | Input coins vector (Token A)
- `by_amount_in` | `bool` | Whether to specify exact input amount
- `amount` | `u64` | Swap amount (input or output depending on by_amount_in)
- `amount_limit` | `u64` | Minimum output amount for slippage protection
- `sqrt_price_limit` | `u128` | Square root price limit for swap
- `clock` | `&Clock` | Sui clock object for timing
- `_order_id` | `u64` | Order identifier (unused in implementation)
- `_decimal` | `u8` | Token decimal (unused in implementation)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<CoinTypeB>, u64)` - Output coin (Token B) and actual amount received



**Error Conditions**:
- `E_CETUS_MIN_RETURN_NOT_REACH`: Output amount below minimum threshold

##### cetus_swap_b2a_with_return
```move
public fun cetus_swap_b2a_with_return<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coins_b: vector<Coin<CoinTypeB>>,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<CoinTypeA>, u64)
```

**Purpose**: Execute B-to-A swap through Cetus concentrated liquidity protocol.

**Parameters**: Same as `cetus_swap_a2b_with_return` but with coins_b input and CoinTypeA output

**Returns**: `(Coin<CoinTypeA>, u64)` - Output coin (Token A) and actual amount received

#### Turbos CLMM Integration

##### turbos_swap_a_b_with_return
```move
public fun turbos_swap_a_b_with_return<CoinTypeA, CoinTypeB, FeeType>(
    pool: &mut Pool<CoinTypeA, CoinTypeB, FeeType>,
    coins_a: vector<Coin<CoinTypeA>>,
    amount: u64,
    amount_threshold: u64,
    sqrt_price_limit: u128,
    is_exact_in: bool,
    recipient: address,
    deadline: u64,
    clock: &Clock,
    versioned: &Versioned,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<CoinTypeB>, u64)
```

**Purpose**: Execute A-to-B swap through Turbos concentrated liquidity protocol.

**Parameters**:
- `pool` | `&mut Pool<CoinTypeA, CoinTypeB, FeeType>` | Turbos pool with fee tier
- `coins_a` | `vector<Coin<CoinTypeA>>` | Input coins vector (Token A)
- `amount` | `u64` | Swap amount
- `amount_threshold` | `u64` | Amount threshold for slippage protection
- `sqrt_price_limit` | `u128` | Square root price limit for slippage control
- `is_exact_in` | `bool` | Whether to use exact input (true) or exact output (false)
- `recipient` | `address` | Address to receive output tokens
- `deadline` | `u64` | Transaction deadline timestamp
- `clock` | `&Clock` | Sui clock object for time validation
- `versioned` | `&Versioned` | Turbos protocol version configuration
- `_order_id` | `u64` | Order identifier (unused in implementation)
- `_decimal` | `u8` | Token decimal (unused in implementation)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<CoinTypeB>, u64)` - Output coin (Token B) and actual amount received



#### SuiSwap Integration

##### suiswap_x_2_y_with_return
```move
public fun suiswap_x_2_y_with_return<Ty0, Ty1>(
    pool: &mut Pool<Ty0, Ty1>,
    coins: vector<Coin<Ty0>>,
    amount_in: u64,
    min_out: u64,
    clock: &Clock,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<Ty1>, u64)
```

**Purpose**: Execute X-to-Y swap through SuiSwap native AMM protocol.

**Parameters**:
- `pool` | `&mut Pool<Ty0, Ty1>` | SuiSwap pool for the trading pair
- `coins` | `vector<Coin<Ty0>>` | Input coins vector (Token X)
- `amount_in` | `u64` | Input amount to swap
- `min_out` | `u64` | Minimum output amount for slippage protection
- `clock` | `&Clock` | Sui clock object for timing
- `_order_id` | `u64` | Order identifier (unused in implementation)
- `_decimal` | `u8` | Token decimal (unused in implementation)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<Ty1>, u64)` - Output coin (Token Y) and actual amount received



##### suiswap_y_2_x_with_return
```move
public fun suiswap_y_2_x_with_return<Ty0, Ty1>(
    pool: &mut Pool<Ty0, Ty1>,
    coins: vector<Coin<Ty1>>,
    amount_in: u64,
    min_out: u64,
    clock: &Clock,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<Ty0>, u64)
```

**Purpose**: Execute Y-to-X swap through SuiSwap native AMM protocol.

**Parameters**: Same as `suiswap_x_2_y_with_return` but with Ty1 input coins and Ty0 output

**Returns**: `(Coin<Ty0>, u64)` - Output coin (Token X) and actual amount received

#### BlueMove Integration

##### bluemove_swap_exact_input_with_return
```move
public fun bluemove_swap_exact_input_with_return<T0, T1>(
    amount_in: u64,
    coin_in: Coin<T0>,
    min_return: u64,
    dex_info: &mut Dex_Info,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<T1>, u64)
```

**Purpose**: Execute exact input swap through BlueMove AMM protocol.

**Parameters**:
- `amount_in` | `u64` | Input amount to swap
- `coin_in` | `Coin<T0>` | Input coin (exact amount)
- `min_return` | `u64` | Minimum output amount for slippage protection
- `dex_info` | `&mut Dex_Info` | BlueMove DEX information and configuration
- `_order_id` | `u64` | Order identifier (unused in implementation)
- `_decimal` | `u8` | Token decimal (unused in implementation)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<T1>, u64)` - Output coin and actual amount received

##### bluemove_stable_swap_exact_input_with_return
```move
public fun bluemove_stable_swap_exact_input_with_return<T0, T1>(
    coin_in: Coin<T0>,
    amount_in: u64,
    min_return: u64,
    dex_stable_info: &mut Dex_Stable_Info,
    clock: &Clock,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<T1>, u64)
```

**Purpose**: Execute exact input swap through BlueMove stable swap (low slippage for correlated assets).

**Parameters**:
- `coin_in` | `Coin<T0>` | Input coin (exact amount)
- `amount_in` | `u64` | Input amount to swap
- `min_return` | `u64` | Minimum output amount for slippage protection
- `dex_stable_info` | `&mut Dex_Stable_Info` | BlueMove stable swap configuration
- `clock` | `&Clock` | Sui clock object for timing
- `_order_id` | `u64` | Order identifier (unused in implementation)
- `_decimal` | `u8` | Token decimal (unused in implementation)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<T1>, u64)` - Output coin and actual amount received



#### DeepBook Integration

##### deepbook_swap_base_to_quote_with_return
```move
public fun deepbook_swap_base_to_quote_with_return<BaseAsset, QuoteAsset>(
    self: &mut Pool<BaseAsset, QuoteAsset>,
    base_in: Coin<BaseAsset>,
    min_quote_out: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Coin<QuoteAsset>, u64)
```

**Purpose**: Execute base-to-quote swap through DeepBook central limit order book.

**Parameters**:
- `self` | `&mut Pool<BaseAsset, QuoteAsset>` | DeepBook pool for the trading pair
- `base_in` | `Coin<BaseAsset>` | Input base asset coin
- `min_quote_out` | `u64` | Minimum quote asset output
- `clock` | `&Clock` | Sui clock for order timing
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<QuoteAsset>, u64)` - Output quote asset coin and amount

##### deepbook_swap_quote_to_base_with_return
```move
public fun deepbook_swap_quote_to_base_with_return<BaseAsset, QuoteAsset>(
    self: &mut Pool<BaseAsset, QuoteAsset>,
    quote_in: Coin<QuoteAsset>,
    min_base_out: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Coin<BaseAsset>, u64)
```

**Purpose**: Execute quote-to-base swap through DeepBook central limit order book.

**Parameters**:
- `self` | `&mut Pool<BaseAsset, QuoteAsset>` | DeepBook pool for the trading pair
- `quote_in` | `Coin<QuoteAsset>` | Input quote asset coin
- `min_base_out` | `u64` | Minimum base asset output
- `clock` | `&Clock` | Sui clock for order timing
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<BaseAsset>, u64)` - Output base asset coin and amount

#### MovePump Integration

##### movepump_buy_returns
```move
public fun movepump_buy_returns<CoinType>(
    config: &mut Configuration,
    sui_coin: Coin<SUI>,
    dex_info: &mut Dex_Info,
    coin_min_out: u64,
    clock: &Clock,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<CoinType>, u64)
```

**Purpose**: Buy tokens through MovePump meme token trading protocol.

**Parameters**:
- `config` | `&mut Configuration` | MovePump protocol configuration
- `sui_coin` | `Coin<SUI>` | Input SUI coin for purchase
- `dex_info` | `&mut Dex_Info` | MovePump DEX information
- `coin_min_out` | `u64` | Minimum output tokens
- `clock` | `&Clock` | Sui clock for timing
- `_order_id` | `u64` | Order identifier (unused in implementation)
- `_decimal` | `u8` | Token decimal (unused in implementation)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<CoinType>, u64)` - Output tokens and amount

##### movepump_sell_returns
```move
public fun movepump_sell_returns<CoinType>(
    config: &mut Configuration,
    coin: Coin<CoinType>,
    sui_min_out: u64,
    clock: &Clock,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<SUI>, u64)
```

**Purpose**: Sell tokens through MovePump meme token trading protocol.

**Parameters**:
- `config` | `&mut Configuration` | MovePump protocol configuration
- `coin` | `Coin<CoinType>` | Input tokens to sell
- `sui_min_out` | `u64` | Minimum SUI output
- `clock` | `&Clock` | Sui clock for timing
- `_order_id` | `u64` | Order identifier (unused in implementation)
- `_decimal` | `u8` | Token decimal (unused in implementation)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<SUI>, u64)` - Output SUI and amount



#### Liquid Staking Integration (AFSUI)

##### afsui_swap_a2b_with_return
```move
public fun afsui_swap_a2b_with_return(
    staked_sui_vault: &mut StakedSuiVault,
    safe: &mut Safe<TreasuryCap<AFSUI>>,
    sui_system_state: &mut 0x3::sui_system::SuiSystemState,
    referral_vault: &ReferralVault,
    coin_in: Coin<SUI>,
    validater_address: address,
    ctx: &mut TxContext,
): (Coin<AFSUI>, u64)
```

**Purpose**: Stake SUI and receive AFSUI (Aftermath Finance liquid staked SUI).

**Parameters**:
- `staked_sui_vault` | `&mut StakedSuiVault` | AFSUI staking vault
- `safe` | `&mut Safe<TreasuryCap<AFSUI>>` | Treasury cap safety wrapper
- `sui_system_state` | `&mut SuiSystemState` | Sui network staking state
- `referral_vault` | `&ReferralVault` | Referral tracking vault
- `coin_in` | `Coin<SUI>` | Input SUI to stake
- `validater_address` | `address` | Validator address for staking delegation
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<AFSUI>, u64)` - AFSUI tokens and amount received



##### afsui_swap_b2a_with_return
```move
public fun afsui_swap_b2a_with_return(
    staked_sui_vault: &mut StakedSuiVault,
    safe: &Safe<TreasuryCap<AFSUI>>,
    referral_vault: &ReferralVault,
    treasury: &mut Treasury,
    coin_in: Coin<AFSUI>,
    ctx: &mut TxContext,
): (Coin<SUI>, u64)
```

**Purpose**: Unstake AFSUI and receive SUI plus accrued staking rewards.

**Parameters**:
- `staked_sui_vault` | `&mut StakedSuiVault` | AFSUI staking vault
- `safe` | `&Safe<TreasuryCap<AFSUI>>` | Treasury cap safety wrapper (immutable reference)
- `referral_vault` | `&ReferralVault` | Referral tracking vault
- `treasury` | `&mut Treasury` | AFSUI treasury for unstaking operations
- `coin_in` | `Coin<AFSUI>` | Input AFSUI to unstake
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<SUI>, u64)` - SUI tokens and amount received

#### Kriya Integration

##### kriya_clmm_swap_token_x_with_return
```move
public fun kriya_clmm_swap_token_x_with_return<T0, T1>(
    pool: &mut Pool<T0, T1>,
    coin_x: Coin<T0>,
    amount_in: u64,
    min_out: u64,
    clock: &Clock,
    version: &Version,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<T1>, u64)
```

**Purpose**: Execute Token X swap through Kriya concentrated liquidity protocol.

**Parameters**:
- `pool` | `&mut Pool<T0, T1>` | Kriya CLMM pool
- `coin_x` | `Coin<T0>` | Input coin (Token X)
- `amount_in` | `u64` | Input amount to swap
- `min_out` | `u64` | Minimum output amount
- `clock` | `&Clock` | Sui clock for timing
- `version` | `&Version` | Kriya version configuration
- `_order_id` | `u64` | Order identifier (unused)
- `_decimal` | `u8` | Token decimal (unused)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<T1>, u64)` - Output coin (Token Y) and amount

##### kriya_clmm_swap_token_y_with_return
```move
public fun kriya_clmm_swap_token_y_with_return<T0, T1>(
    pool: &mut Pool<T0, T1>,
    coin_y: Coin<T1>,
    amount_in: u64,
    min_out: u64,
    clock: &Clock,
    version: &Version,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<T0>, u64)
```

**Purpose**: Execute Token Y swap through Kriya concentrated liquidity protocol.

**Parameters**: Same as `kriya_clmm_swap_token_x_with_return` but with Token Y input and Token X output

**Returns**: `(Coin<T0>, u64)` - Output coin (Token X) and amount

##### kriya_amm_swap_token_x_with_return
```move
public fun kriya_amm_swap_token_x_with_return<T0, T1>(
    pool: &mut Pool<T0, T1>,
    coin_in: Coin<T0>,
    amount_in: u64,
    min_out: u64,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<T1>, u64)
```

**Purpose**: Execute Token X swap through Kriya AMM protocol.

**Parameters**:
- `pool` | `&mut Pool<T0, T1>` | Kriya AMM pool
- `coin_in` | `Coin<T0>` | Input coin (Token X)
- `amount_in` | `u64` | Input amount to swap
- `min_out` | `u64` | Minimum output amount
- `_order_id` | `u64` | Order identifier (unused)
- `_decimal` | `u8` | Token decimal (unused)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<T1>, u64)` - Output coin (Token Y) and amount

##### kriya_amm_swap_token_y_with_return
```move
public fun kriya_amm_swap_token_y_with_return<T0, T1>(
    pool: &mut Pool<T0, T1>,
    coin_in: Coin<T1>,
    amount_in: u64,
    min_out: u64,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<T0>, u64)
```

**Purpose**: Execute Token Y swap through Kriya AMM protocol.

**Parameters**: Same as `kriya_amm_swap_token_x_with_return` but with Token Y input and Token X output

**Returns**: `(Coin<T0>, u64)` - Output coin (Token X) and amount

#### Aftermath Integration

##### aftermath_swap_exact_in_with_return
```move
public fun aftermath_swap_exact_in_with_return<T0, T1, T2>(
    pool: &mut Pool<T0>,
    pool_registry: &PoolRegistry,
    vault: &ProtocolFeeVault,
    treasury: &mut Treasury,
    insurance_fund: &mut InsuranceFund,
    referral_vault: &ReferralVault,
    coin_in: Coin<T1>,
    amount_in: u64,
    expected_coin_out: u64,
    allowable_slippage: u64,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<T2>, u64)
```

**Purpose**: Execute exact input swap through Aftermath AMM protocol.

**Parameters**:
- `pool` | `&mut Pool<T0>` | Aftermath pool
- `pool_registry` | `&PoolRegistry` | Pool registry
- `vault` | `&ProtocolFeeVault` | Protocol fee vault
- `treasury` | `&mut Treasury` | Treasury
- `insurance_fund` | `&mut InsuranceFund` | Insurance fund
- `referral_vault` | `&ReferralVault` | Referral vault
- `coin_in` | `Coin<T1>` | Input coin
- `amount_in` | `u64` | Input amount
- `expected_coin_out` | `u64` | Expected output amount
- `allowable_slippage` | `u64` | Allowable slippage
- `_order_id` | `u64` | Order identifier (unused)
- `_decimal` | `u8` | Token decimal (unused)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<T2>, u64)` - Output coin and amount

#### FlowX Integration

##### flowxv3_swap_a2b_with_return
```move
public fun flowxv3_swap_a2b_with_return<CoinTypeA, CoinTypeB>(
    clock: &Clock,
    versioned: &Versioned,
    pool_registry: &mut PoolRegistry,
    fee_rate: u64,
    coins_a: Coin<CoinTypeA>,
    by_amount_in: bool,
    sqrt_price_max_limit: u128,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<CoinTypeB>, u64)
```

**Purpose**: Execute A-to-B swap through FlowX v3 concentrated liquidity protocol.

**Parameters**:
- `clock` | `&Clock` | Sui clock
- `versioned` | `&Versioned` | FlowX version configuration
- `pool_registry` | `&mut PoolRegistry` | Pool registry
- `fee_rate` | `u64` | Fee rate for the pool
- `coins_a` | `Coin<CoinTypeA>` | Input coin (Token A)
- `by_amount_in` | `bool` | Exact input mode
- `sqrt_price_max_limit` | `u128` | Price limit
- `_order_id` | `u64` | Order identifier (unused)
- `_decimal` | `u8` | Token decimal (unused)
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<CoinTypeB>, u64)` - Output coin (Token B) and amount

##### flowxv3_swap_b2a_with_return
```move
public fun flowxv3_swap_b2a_with_return<CoinTypeA, CoinTypeB>(
    clock: &Clock,
    versioned: &Versioned,
    pool_registry: &mut PoolRegistry,
    fee_rate: u64,
    coins_b: Coin<CoinTypeB>,
    by_amount_in: bool,
    sqrt_price_max_limit: u128,
    _order_id: u64,
    _decimal: u8,
    ctx: &mut TxContext
): (Coin<CoinTypeA>, u64)
```

**Purpose**: Execute B-to-A swap through FlowX v3 concentrated liquidity protocol.

**Parameters**: Same as `flowxv3_swap_a2b_with_return` but with Token B input and Token A output

**Returns**: `(Coin<CoinTypeA>, u64)` - Output coin (Token A) and amount

##### flowx_swap_exact_input_direct_with_return
```move
public fun flowx_swap_exact_input_direct_with_return<CoinTypeA, CoinTypeB>(
    container: &mut Container,
    input: Coin<CoinTypeA>,
    ctx: &mut TxContext
): (Coin<CoinTypeB>, u64)
```

**Purpose**: Execute direct exact input swap through FlowX v2 protocol.

**Parameters**:
- `container` | `&mut Container` | FlowX v2 container
- `input` | `Coin<CoinTypeA>` | Input coin
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<CoinTypeB>, u64)` - Output coin and amount



### DeFi Protocol Integrations (Extended Router)

#### Haedal Liquid Staking

##### haedal_swap_a2b_with_return
```move
public fun haedal_swap_a2b_with_return(
    sui_system_state: &mut 0x3::sui_system::SuiSystemState,
    staking: &mut Staking,
    coin_in: Coin<SUI>,
    validater_address: address,
    ctx: &mut TxContext,
): (Coin<HASUI>, u64)
```

**Purpose**: Stake SUI through Haedal protocol and receive haSUI liquid staking tokens.

**Parameters**:
- `sui_system_state` | `&mut SuiSystemState` | Sui network staking state
- `staking` | `&mut Staking` | Haedal staking contract
- `coin_in` | `Coin<SUI>` | Input SUI to stake
- `validater_address` | `address` | Specific validator to delegate to
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<HASUI>, u64)` - haSUI tokens and amount received



##### haedal_swap_b2a_with_return
```move
public fun haedal_swap_b2a_with_return(
    sui_system_state: &mut 0x3::sui_system::SuiSystemState,
    staking: &mut Staking,
    coin_in: Coin<HASUI>,
    ctx: &mut TxContext,
): (Coin<SUI>, u64)
```

**Purpose**: Unstake haSUI and receive SUI plus accrued rewards through Haedal protocol.

#### Scallop Lending Integration

##### scallop_swap_exact_swap_a2b_with_return
```move
public fun scallop_swap_exact_swap_a2b_with_return<CoinType0, CoinType1>(
    market: &mut Market,
    s_coin_treasury: &mut SCoinTreasury<CoinType0>,
    coin: Coin<CoinType0>,
    min_amount: u64,
    ctx: &mut TxContext
): (Coin<CoinType1>, u64)
```

**Purpose**: Supply tokens to Scallop lending market and receive interest-bearing s-tokens.

**Parameters**:
- `market` | `&mut Market` | Scallop lending market state
- `s_coin_treasury` | `&mut SCoinTreasury<CoinType0>` | S-coin treasury for token minting
- `coin` | `Coin<CoinType0>` | Input token to supply
- `min_amount` | `u64` | Minimum s-token output
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<CoinType1>, u64)` - S-tokens and amount received



#### Momentum v3 Integration

##### momentum_swap_a2b_with_return
```move
public fun momentum_swap_a2b_with_return<CoinType0, CoinType1>(
    pool: &mut Pool<CoinType0, CoinType1>,
    coin_a: Coin<CoinType0>,
    amount_specified: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    version: &Mntv3Version,
    ctx: &mut TxContext,
): (Coin<CoinType1>, u64)
```

**Purpose**: Execute A-to-B swap through Momentum v3 concentrated liquidity protocol.

**Parameters**:
- `pool` | `&mut Pool<CoinType0, CoinType1>` | Momentum v3 pool
- `coin_a` | `Coin<CoinType0>` | Input coin (Token A)
- `amount_specified` | `u64` | Specified swap amount
- `sqrt_price_limit` | `u128` | Square root price limit for slippage control
- `clock` | `&Clock` | Sui clock for timing
- `version` | `&Mntv3Version` | Momentum v3 version compatibility
- `ctx` | `&mut TxContext` | Transaction context

**Returns**: `(Coin<CoinType1>, u64)` - Output coin (Token B) and amount



#### BlueFin Spot Trading

##### bluefin_spot_swap_a2b_with_return
```move
public fun bluefin_spot_swap_a2b_with_return<CoinTypeA, CoinTypeB>(
    clock: &Clock,
    protocol_config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coins_a: Coin<CoinTypeA>,
    amount_specified: u64,
    sqrt_price_limit: u128,
    ctx: &mut TxContext
): (Coin<CoinTypeB>, u64)
```

**Purpose**: Execute A-to-B swap through BlueFin professional spot trading protocol.

**Parameters**:
- `clock` | `&Clock` | Sui clock for timing validation
- `protocol_config` | `&GlobalConfig` | BlueFin global configuration
- `pool` | `&mut Pool<CoinTypeA, CoinTypeB>` | BlueFin trading pool
- `coins_a` | `Coin<CoinTypeA>` | Input coin (Token A)
- `amount_specified` | `u64` | Specified swap amount
- `sqrt_price_limit` | `u128` | Price limit for professional trading
- `ctx` | `&mut TxContext` | Transaction context



#### MetaVault Integration

##### metastable_swap_a2b_with_return
```move
public fun metastable_swap_a2b_with_return<CoinTypeA, CoinTypeB>(
    vault: &mut Vault<CoinTypeA, CoinTypeB>,
    deposit_cap: &DepositCap<CoinTypeA, CoinTypeB>,
    withdraw_cap: &WithdrawCap<CoinTypeA, CoinTypeB>,
    coin_a: Coin<CoinTypeA>,
    min_amount: u64,
    version: &Version,
    ctx: &mut TxContext
): (Coin<CoinTypeB>, u64)
```

**Purpose**: Execute A-to-B swap through MetaVault metastable asset management protocol.

**Parameters**:
- `vault` | `&mut Vault<CoinTypeA, CoinTypeB>` | MetaVault vault for asset pair
- `deposit_cap` | `&DepositCap<CoinTypeA, CoinTypeB>` | Deposit capability
- `withdraw_cap` | `&WithdrawCap<CoinTypeA, CoinTypeB>` | Withdraw capability
- `coin_a` | `Coin<CoinTypeA>` | Input coin (Token A)
- `min_amount` | `u64` | Minimum output for slippage protection
- `version` | `&Version` | MetaVault version compatibility
- `ctx` | `&mut TxContext` | Transaction context



#### Magma CLMM Integration

##### magma_swap_token_x_with_return
```move
public fun magma_swap_token_x_with_return<T0, T1>(
    global_config: &MagmaGlobalConfig,
    pool: &mut MagmaPool<T0, T1>,
    coin_x: Coin<T0>,
    amount: u64,
    sqrt_price_limit: u128,
    is_exact_in: bool,
    clock: &Clock,
    ctx: &mut TxContext
): (Coin<T1>, u64)
```

**Purpose**: Execute Token X swap through Magma concentrated liquidity protocol.

**Parameters**:
- `global_config` | `&MagmaGlobalConfig` | Magma global configuration
- `pool` | `&mut MagmaPool<T0, T1>` | Magma CLMM pool
- `coin_x` | `Coin<T0>` | Input coin (Token X)
- `amount` | `u64` | Swap amount
- `sqrt_price_limit` | `u128` | Square root price limit
- `is_exact_in` | `bool` | Exact input vs exact output mode
- `clock` | `&Clock` | Sui clock for timing
- `ctx` | `&mut TxContext` | Transaction context



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



---

*This technical reference provides complete API documentation for both DEX Router contracts. For implementation examples and integration patterns, see the accompanying guides.md documentation.* 