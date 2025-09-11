# DEX-Router-Aptos Technical Reference

## Contract Overview

The DEX-Router-Aptos is a sophisticated Move smart contract system that provides DEX aggregation and optimal routing capabilities. This document provides complete technical specifications for all exported interfaces and functions.

> **📝 Auto-Generated Documentation**: This technical reference is automatically generated from Move source code NatSpec comments. For the most up-to-date information, refer to the source contracts.

### Main Package
- **Name**: DEX-Router-Aptos-V1
- **Version**: v2.0.0
- **Move Version**: 2.0
- **License**: MIT
- **Package Address**: `0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1`

## Core Interfaces

### OrderRecord Event Structure
```move
#[event]
struct OrderRecord has drop, store {
    dex_type: u8,                      // Protocol identifier constant
    pool_type: u64,                    // Pool-specific configuration parameter
    x_type_info: TypeInfo,             // Input asset type information
    y_type_info: TypeInfo,             // Output asset type information  
    asset_object_in: Object<Metadata>, // Fungible Asset input metadata object
    asset_object_out: Object<Metadata>, // Fungible Asset output metadata object
    is_in_FA: bool,                    // Input asset format flag (true=FA, false=Coin)
    is_out_FA: bool,                   // Output asset format flag (true=FA, false=Coin)
    input_amount: u64,                 // Actual input amount transferred
    output_amount: u64,                // Actual output amount received
    time_stamp: u64                    // Execution timestamp in microseconds
}
```

## Public Functions

### Multi-Hop Routing Functions

#### `unxswap` - Primary Multi-Hop Entry Point

Executes optimal multi-hop routing across up to 3 DEX protocols with comprehensive slippage protection and dual asset format support.

```move
public entry fun unxswap<X, Y, Z, M, E1, E2, E3>(
    sender: &signer,
    x_in: u64,
    min_out: u64,
    dex_types: vector<u8>,
    pool_types: vector<u64>,
    is_x_to_y: vector<bool>,
    asset_objects: vector<Object<Metadata>>,
    is_FA: vector<bool>
)
```

**Parameters:**
- `sender` (signer): Transaction sender and asset owner
- `x_in` (u64): Input amount in native asset decimals
- `min_out` (u64): Minimum output amount for slippage protection
- `dex_types` (vector<u8>): DEX protocol identifiers (1-3 elements)
- `pool_types` (vector<u64>): Protocol-specific pool configurations
- `is_x_to_y` (vector<bool>): Routing direction flags for each hop
- `asset_objects` (vector<Object<Metadata>>): FA metadata objects (exactly 4 elements)
- `is_FA` (vector<bool>): Asset format flags (exactly 4 elements)

**Type Parameters:**
- `X`: Input asset type (Coin or FA phantom type)
- `Y`: First intermediate asset type  
- `Z`: Second intermediate asset type
- `M`: Final output asset type
- `E1`, `E2`, `E3`: LP/Curve types for DEX protocol routing

**Features:**
- Supports 1-3 hop routing with atomic execution
- Mixed Coin/FA format handling in single transaction
- Comprehensive input validation and error handling
- Automatic slippage protection with transaction reversion
- Detailed event emission for each routing hop
- Gas-optimized PDA asset management

**Error Conditions:**
- `E_OUTPUT_LESS_THAN_MINIMUM (2)`: Output below minimum threshold
- `E_LENGTH_NOT_EQUAL (6)`: Inconsistent vector lengths
- `E_OUT_HIP (5)`: More than 3 hops specified
- `E_INVALID_FA_INFO_LENGTH (8)`: Asset vectors not exactly 4 elements
- `E_INVALID_MIN_OUT (9)`: Zero or invalid minimum output

### Router Core Functions

#### `swap` - Single-Hop Protocol Routing

Executes single-hop swap through specified DEX protocol with automatic asset format handling and adapter routing.

```move
public (friend) fun swap<X, Y, E>(
    dex_type: u8,
    pool_type: u64,
    _is_x_to_y: bool,
    asset_object_in: Object<Metadata>,
    asset_object_out: Object<Metadata>,
    is_in_FA: bool,
    is_out_FA: bool
): u64
```

**Parameters:**
- `dex_type` (u8): DEX protocol identifier (see DEX constants)
- `pool_type` (u64): Protocol-specific pool configuration
- `_is_x_to_y` (bool): Routing direction (currently unused, determined by adapters)
- `asset_object_in` (Object<Metadata>): Input asset FA metadata object
- `asset_object_out` (Object<Metadata>): Output asset FA metadata object
- `is_in_FA` (bool): Input asset format flag
- `is_out_FA` (bool): Output asset format flag

**Returns**: `u64` - Status code (0 = success, 3 = unknown DEX)

**Features:**
- Protocol-specific adapter routing
- Automatic FA/Coin format detection and handling
- PDA-based secure asset management
- Error propagation to aggregator layer
- Support for all integrated DEX protocols

**Access Control**: Friend-only access from `dex_router::aggregator`

**Supported Protocols:**

| DEX Type | Protocol | FA Support | Adapter Module |
|----------|----------|------------|----------------|
| 3 | Pontem Liquidswap V1 | ❌ | `pontem_adapter` |
| 7 | PancakeSwap Aptos | ❌ | `pancake_adapter` |
| 8 | Pontem Liquidswap V2 | ❌ | `pontem_adapter_v2` |
| 9 | Cellana Finance | ✅ | `cellana_adapter` |
| 10 | Hyperion Protocol | ✅ | `hyperion_adapter` |

## Events Reference

### OrderRecord Event

**Event Signature:**
```move
#[event]
struct OrderRecord has drop, store { /* fields above */ }
```

**Emission Conditions:**
- Emitted for each individual swap in multi-hop routing
- Generated after successful swap execution with actual amounts
- Includes complete asset type and format information
- Contains precise execution timestamp

**Parameter Details:**

| Field | Type | Usage | Example Values |
|-------|------|-------|----------------|
| `dex_type` | `u8` | Protocol identification | `3` (Pontem), `9` (Cellana) |
| `pool_type` | `u64` | Pool configuration | `0` (standard), `1` (stable) |
| `x_type_info` | `TypeInfo` | Input asset type info | `Coin<APT>` type information |
| `y_type_info` | `TypeInfo` | Output asset type info | `Coin<USDC>` type information |
| `asset_object_in` | `Object<Metadata>` | Input FA metadata | FA object address |
| `asset_object_out` | `Object<Metadata>` | Output FA metadata | FA object address |
| `is_in_FA` | `bool` | Input format flag | `false` (Coin), `true` (FA) |
| `is_out_FA` | `bool` | Output format flag | `false` (Coin), `true` (FA) |
| `input_amount` | `u64` | Actual input transferred | `100000000` (1 APT with 8 decimals) |
| `output_amount` | `u64` | Actual output received | `4500000` (4.5 USDC with 6 decimals) |
| `time_stamp` | `u64` | Execution timestamp | `1698765432000000` (microseconds) |

## Error Reference

### Standard Error Codes

```move
// Core error constants
const E_OUTPUT_LESS_THAN_MINIMUM: u64 = 2;
const E_UNKNOWN_DEX: u64 = 3;
const E_FA_NOT_SUPPORTED: u64 = 4;
const E_OUT_HIP: u64 = 5;
const E_LENGTH_NOT_EQUAL: u64 = 6;
const E_FAULT_OUT_AMOUNT: u64 = 7;
const E_INVALID_FA_INFO_LENGTH: u64 = 8;
const E_INVALID_MIN_OUT: u64 = 9;

// Router-specific errors
const E_NORMAL: u64 = 0;
```

### Error Descriptions and Solutions

#### `E_OUTPUT_LESS_THAN_MINIMUM (2)`
**Cause**: Actual swap output is below specified minimum threshold  
**Solution**: Increase slippage tolerance or check market conditions  
**Prevention**: Use realistic slippage calculations based on liquidity

#### `E_UNKNOWN_DEX (3)`
**Cause**: Specified DEX type is not supported or not implemented  
**Solution**: Use supported DEX constants (3, 7, 8, 9, 10)  
**Prevention**: Validate DEX types against supported protocol list

#### `E_OUT_HIP (5)`
**Cause**: More than 3 routing hops specified  
**Solution**: Reduce routing path to maximum 3 hops  
**Prevention**: Design routing paths within system limits

#### `E_LENGTH_NOT_EQUAL (6)`
**Cause**: Inconsistent vector lengths in routing parameters  
**Solution**: Ensure all routing vectors have equal length  
**Prevention**: Validate vector lengths before function calls

#### `E_INVALID_FA_INFO_LENGTH (8)`
**Cause**: Asset object or FA flag vectors not exactly 4 elements  
**Solution**: Provide exactly 4 elements in asset_objects and is_FA vectors  
**Prevention**: Use proper vector construction with required length

#### `E_INVALID_MIN_OUT (9)`
**Cause**: Zero or invalid minimum output specified  
**Solution**: Specify positive minimum output for slippage protection  
**Prevention**: Always set reasonable minimum output values

#### `E_FA_NOT_SUPPORTED (4)`
**Cause**: Fungible Asset format used with non-FA-supporting protocol  
**Solution**: Use FA-supporting protocols (Cellana, Hyperion) for FA assets  
**Prevention**: Check protocol capabilities before asset format selection

## Constants Reference

### DEX Protocol Constants

```move
const DEX_HIPPO: u8 = 1;      // Hippo Labs (Ready-to-deploy)
const DEX_ECONIA: u8 = 2;     // Econia CLOB (Ready-to-deploy)
const DEX_PONTEM: u8 = 3;     // ✅ Pontem Liquidswap V1
const DEX_BASIQ: u8 = 4;      // Basiq Protocol (Ready-to-deploy)
const DEX_UNISWAP: u8 = 5;    // Uniswap V2/V3 (Ready-to-deploy)
const DEX_ANIME: u8 = 6;      // AnimeSwap (Ready-to-deploy)
const DEX_PANCAKE: u8 = 7;    // ✅ PancakeSwap Aptos
const DEX_PONTEM_V2: u8 = 8;  // ✅ Pontem Liquidswap V2
const DEX_CELLANA: u8 = 9;    // ✅ Cellana Finance (FA Support)
const DEX_HYPERION: u8 = 10;  // ✅ Hyperion Protocol (FA Support)
```

### Pool Type Constants by Protocol

#### Pontem Liquidswap (Types 3, 8)
- `0`: Standard AMM pool
- Custom curve types depend on pool configuration

#### PancakeSwap (Type 7)
- `0`: Standard V2 AMM pool

#### Cellana Finance (Type 9)
- `0`: Stable swap pool (minimal price impact)
- `1`: Volatile pair pool (standard AMM)

#### Hyperion Protocol (Type 10)
- `0`: 0.01% fee tier (very stable pairs)
- `1`: 0.05% fee tier (stable pairs)
- `2`: 0.3% fee tier (standard pairs)
- `3`: 1% fee tier (exotic pairs)
- `4`: 0.1% fee tier (custom pairs)

### Asset Format Compatibility Matrix

| Protocol | Coin Input | FA Input | Coin Output | FA Output | Mixed Format |
|----------|------------|----------|-------------|-----------|--------------|
| Pontem V1/V2 | ✅ | ❌ | ✅ | ❌ | ❌ |
| PancakeSwap | ✅ | ❌ | ✅ | ❌ | ❌ |
| Cellana | ✅ | ✅ | ✅ | ✅ | ✅ |
| Hyperion | ✅ | ✅ | ✅ | ✅ | ✅ |

### Resource Account Management

#### `get_pda_manager` - Resource Account Access

```move
public (friend) fun get_pda_manager(): signer acquires ResourceAccount
```

**Purpose**: Retrieve PDA signer capability for secure intermediate asset operations.

**Returns**: `signer` - Resource account signer for asset custody operations

**Features/Capabilities:**
- Secure PDA pattern implementation
- Friend-only access control
- Automatic resource account creation and management
- Isolated permission boundaries

**Access Control**: Friend-only access from `dex_router::aggregator` and `dex_router::router`

**Account Requirements**: 
- ResourceAccount must be initialized at deployer address
- Seed: `b"okx.dex.escrow.account.5"`

#### `pda_register_coins` - Automatic Coin Registration

```move
public (friend) fun pda_register_coins<X, Y>(accountSinger: &signer)
```

**Purpose**: Automatically register coin types for PDA to enable asset deposits and withdrawals.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `accountSinger` | `&signer` | PDA signer capability |

**Type Parameters:**
- `X`: Input coin type to register
- `Y`: Output coin type to register

**Features/Capabilities:**
- Automatic coin registration checks
- Idempotent operation (safe to call multiple times)
- Support for arbitrary coin types
- Gas-optimized registration logic

**Access Control**: Friend-only access from router and aggregator modules

#### `init` - Resource Account Initialization

```move
public entry fun init(deployer: &signer)
```

**Purpose**: Initialize resource account infrastructure for secure PDA operations.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `deployer` | `&signer` | Deployer account for resource account creation |

**Features/Capabilities:**
- One-time initialization of resource account
- Secure signer capability storage
- Deterministic account address generation
- Foundation for all PDA operations

**Usage Example:**
```move
// Initialize during deployment
dex_router::proxy::init(&deployer_account);
```

## Events Reference

### OrderRecord Event

**Event Signature:**
```move
#[event]
struct OrderRecord has drop, store { /* fields above */ }
```

**Emission Conditions:**
- Emitted for each individual swap in multi-hop routing
- Generated after successful swap execution with actual amounts
- Includes complete asset type and format information
- Contains precise execution timestamp

**Parameter Details:**

| Field | Type | Usage | Example Values |
|-------|------|-------|----------------|
| `dex_type` | `u8` | Protocol identification | `3` (Pontem), `9` (Cellana) |
| `pool_type` | `u64` | Pool configuration | `0` (standard), `1` (stable) |
| `x_type_info` | `TypeInfo` | Input asset type info | `Coin<APT>` type information |
| `y_type_info` | `TypeInfo` | Output asset type info | `Coin<USDC>` type information |
| `asset_object_in` | `Object<Metadata>` | Input FA metadata | FA object address |
| `asset_object_out` | `Object<Metadata>` | Output FA metadata | FA object address |
| `is_in_FA` | `bool` | Input format flag | `false` (Coin), `true` (FA) |
| `is_out_FA` | `bool` | Output format flag | `false` (Coin), `true` (FA) |
| `input_amount` | `u64` | Actual input transferred | `100000000` (1 APT with 8 decimals) |
| `output_amount` | `u64` | Actual output received | `4500000` (4.5 USDC with 6 decimals) |
| `time_stamp` | `u64` | Execution timestamp | `1698765432000000` (microseconds) |

**Monitoring and Indexing Usage:**
```typescript
// Event filtering for analytics
const events = await aptos.getEventsByEventType({
  eventType: "0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1::aggregator::OrderRecord",
  limit: 100
});

// Parse event data
events.forEach(event => {
  const {
    dex_type,
    pool_type,
    input_amount,
    output_amount,
    time_stamp
  } = event.data;
  
  // Analytics processing
  console.log(`Swap: ${input_amount} → ${output_amount} via DEX ${dex_type}`);
});
```

## State Management

### Resource Account Pattern

DEX-Router-Aptos implements the **Resource Account (PDA)** pattern for secure intermediate asset custody:

**Resource Account Structure:**
```move
// Stored at deployer address
struct ResourceAccount has key, store {
    signer_cap: account::SignerCapability  // Secure signing capability
}
```

**Key Properties:**
- **Deterministic Address**: Generated from deployer + seed for predictable addressing
- **Secure Custody**: Isolated account for intermediate asset storage
- **Friend-Only Access**: Controlled access via module friend declarations
- **Gas Optimization**: Reduced transaction costs through efficient account reuse

**Asset Flow:**
```
1. User assets → PDA (secure transfer)
2. PDA → DEX Adapter (protocol interaction)  
3. DEX Adapter → PDA (receive output)
4. PDA → User (final transfer with validation)
```

### Asset Format Management

#### Coin Asset Handling

```move
// Coin deposit pattern
let coin_x = coin::withdraw<X>(sender, x_in);
coin::deposit<X>(signer::address_of(&pda), coin_x);

// Coin withdrawal pattern  
let coin_y_amount = coin::balance<Y>(signer::address_of(&pda));
let coin_y = coin::withdraw<Y>(&pda, coin_y_amount);
check_and_deposit(sender, coin_y);
```

**Features:**
- Automatic coin registration for new asset types
- Balance validation before operations
- Safe transfer patterns with error handling

#### Fungible Asset Handling

```move
// FA deposit pattern
let asset_x = primary_fungible_store::withdraw(sender, asset_object_0, x_in);
primary_fungible_store::deposit(signer::address_of(&pda), asset_x);

// FA withdrawal pattern
let asset_y_amount = primary_fungible_store::balance(signer::address_of(&pda), asset_object_out);
let asset_y = primary_fungible_store::withdraw(&pda, asset_object_out, asset_y_amount);
primary_fungible_store::deposit(signer::address_of(sender), asset_y);
```

**Features:**
- Native FA standard support
- Metadata preservation throughout routing
- Cross-format compatibility with Coin assets

## Error Reference

### Standard Error Codes

```move
// Core error constants
const E_OUTPUT_LESS_THAN_MINIMUM: u64 = 2;
const E_UNKNOWN_DEX: u64 = 3;
const E_NOT_ADMIN: u64 = 4;
const E_OUT_HIP: u64 = 5;
const E_LENGTH_NOT_EQUAL: u64 = 6;
const E_FAULT_OUT_AMOUNT: u64 = 7;
const E_INVALID_FA_INFO_LENGTH: u64 = 8;
const E_INVALID_MIN_OUT: u64 = 9;

// Router-specific errors
const E_NORMAL: u64 = 0;
const E_FA_NOT_SUPPORTED: u64 = 4;
```

### Error Descriptions and Solutions

#### `E_OUTPUT_LESS_THAN_MINIMUM (2)`
**Cause**: Actual swap output is below specified minimum threshold  
**Solution**: Increase slippage tolerance or check market conditions  
**Prevention**: Use realistic slippage calculations based on liquidity

#### `E_UNKNOWN_DEX (3)`
**Cause**: Specified DEX type is not supported or not implemented  
**Solution**: Use supported DEX constants (3, 7, 8, 9, 10)  
**Prevention**: Validate DEX types against supported protocol list

#### `E_OUT_HIP (5)`
**Cause**: More than 3 routing hops specified  
**Solution**: Reduce routing path to maximum 3 hops  
**Prevention**: Design routing paths within system limits

#### `E_LENGTH_NOT_EQUAL (6)`
**Cause**: Inconsistent vector lengths in routing parameters  
**Solution**: Ensure all routing vectors have equal length  
**Prevention**: Validate vector lengths before function calls

#### `E_INVALID_FA_INFO_LENGTH (8)`
**Cause**: Asset object or FA flag vectors not exactly 4 elements  
**Solution**: Provide exactly 4 elements in asset_objects and is_FA vectors  
**Prevention**: Use proper vector construction with required length

#### `E_INVALID_MIN_OUT (9)`
**Cause**: Zero or invalid minimum output specified  
**Solution**: Specify positive minimum output for slippage protection  
**Prevention**: Always set reasonable minimum output values

#### `E_FA_NOT_SUPPORTED (4)`
**Cause**: Fungible Asset format used with non-FA-supporting protocol  
**Solution**: Use FA-supporting protocols (Cellana, Hyperion) for FA assets  
**Prevention**: Check protocol capabilities before asset format selection

### Common Failure Scenarios

#### Insufficient Liquidity
**Symptoms**: `E_OUTPUT_LESS_THAN_MINIMUM` errors during execution  
**Diagnosis**: Check pool liquidity and price impact  
**Resolution**: Use alternative routing paths or reduce trade size

#### Asset Format Mismatch
**Symptoms**: `E_FA_NOT_SUPPORTED` errors  
**Diagnosis**: Verify protocol FA support capabilities  
**Resolution**: Route FA assets through Cellana or Hyperion protocols

#### Invalid Route Configuration
**Symptoms**: `E_LENGTH_NOT_EQUAL` or `E_INVALID_FA_INFO_LENGTH` errors  
**Diagnosis**: Check vector parameter construction  
**Resolution**: Ensure all routing vectors have consistent and correct lengths

## Troubleshooting Guidelines

### Performance Optimization

#### Gas Optimization Strategies
1. **Minimize Hops**: Use fewer routing hops when possible
2. **Batch Operations**: Group multiple swaps in single transaction
3. **PDA Reuse**: Leverage resource account for gas efficiency
4. **Asset Registration**: Pre-register coins to avoid runtime costs

#### Slippage Management
1. **Dynamic Slippage**: Calculate based on current market conditions
2. **Liquidity Checks**: Verify pool liquidity before large trades
3. **Alternative Routing**: Implement fallback routing strategies
4. **Price Impact**: Monitor and limit price impact per trade

### Integration Best Practices

#### Error Handling
```move
// Robust error handling pattern
public entry fun safe_swap_wrapper(sender: &signer, /* parameters */) {
    // Pre-validation
    assert!(min_out > 0, E_INVALID_MIN_OUT);
    assert!(vector::length(&dex_types) <= 3, E_OUT_HIP);
    
    // Protected execution
    aggregator::unxswap</* types */>(/* parameters */);
    
    // Post-validation and cleanup
}
```

#### Event Monitoring
```move
// Comprehensive event tracking
public fun track_swap_performance(events: vector<OrderRecord>): (u64, u64) {
    let total_volume = 0;
    let total_slippage = 0;
    
    let i = 0;
    while (i < vector::length(&events)) {
        let event = vector::borrow(&events, i);
        total_volume = total_volume + event.input_amount;
        // Calculate and track slippage
        i = i + 1;
    };
    
    (total_volume, total_slippage)
}
```

#### Production Deployment
1. **Testing**: Comprehensive testnet validation
2. **Monitoring**: Real-time event tracking and alerting
3. **Security**: Regular security audits and updates
4. **Documentation**: Maintain updated integration documentation

---

## Appendix

### DEX Protocol Constants Reference

```move
const DEX_HIPPO: u8 = 1;      // Hippo Labs (Ready-to-deploy)
const DEX_ECONIA: u8 = 2;     // Econia CLOB (Ready-to-deploy)
const DEX_PONTEM: u8 = 3;     // ✅ Pontem Liquidswap V1
const DEX_BASIQ: u8 = 4;      // Basiq Protocol (Ready-to-deploy)
const DEX_UNISWAP: u8 = 5;    // Uniswap V2/V3 (Ready-to-deploy)
const DEX_ANIME: u8 = 6;      // AnimeSwap (Ready-to-deploy)
const DEX_PANCAKE: u8 = 7;    // ✅ PancakeSwap Aptos
const DEX_PONTEM_V2: u8 = 8;  // ✅ Pontem Liquidswap V2
const DEX_CELLANA: u8 = 9;    // ✅ Cellana Finance (FA Support)
const DEX_HYPERION: u8 = 10;  // ✅ Hyperion Protocol (FA Support)
```

### Pool Type Constants by Protocol

#### Pontem Liquidswap (Types 3, 8)
- `0`: Standard AMM pool
- Custom curve types depend on pool configuration

#### PancakeSwap (Type 7)
- `0`: Standard V2 AMM pool

#### Cellana Finance (Type 9)
- `0`: Stable swap pool (minimal price impact)
- `1`: Volatile pair pool (standard AMM)

#### Hyperion Protocol (Type 10)
- `0`: 0.01% fee tier (very stable pairs)
- `1`: 0.05% fee tier (stable pairs)
- `2`: 0.3% fee tier (standard pairs)
- `3`: 1% fee tier (exotic pairs)
- `4`: 0.1% fee tier (custom pairs)

### Asset Format Compatibility Matrix

| Protocol | Coin Input | FA Input | Coin Output | FA Output | Mixed Format |
|----------|------------|----------|-------------|-----------|--------------|
| Pontem V1/V2 | ✅ | ❌ | ✅ | ❌ | ❌ |
| PancakeSwap | ✅ | ❌ | ✅ | ❌ | ❌ |
| Cellana | ✅ | ✅ | ✅ | ✅ | ✅ |
| Hyperion | ✅ | ✅ | ✅ | ✅ | ✅ |

### Version History

- **V2.0.0**: Current version with full FA support and 5 integrated protocols
- **V1.x**: Legacy version with Coin-only support
- **Future**: Additional protocol integrations and advanced routing features 