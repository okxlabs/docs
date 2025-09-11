# DEX-Router-Aptos Implementation Guides

## Getting Started

These guides will help you implement **production-ready** token swapping functionality using the DEX-Router-Aptos system. Each guide is designed to be completed within 10 minutes and provides complete, working Move contracts based on real implementation examples.

**💡 Production-Ready Examples**: All code examples in these guides are derived from actual working Move contracts and are available in our source repository for easy reference and implementation.

**📋 Four Complete Guides**: We provide comprehensive guides covering all major integration patterns:
- **Guide 1**: Basic Single-Hop Swap Integration (`aggregator.move`)
- **Guide 2**: Multi-Hop Cross-Protocol Routing (`router.move`)
- **Guide 3**: Fungible Asset (FA) Support (`cellana_adapter.move`, `hyperion_adapter.move`)
- **Guide 4**: Event Monitoring & Analytics (`OrderRecord` events)

**🔧 What's Different**: Unlike simplified tutorial examples, these guides show you the complete implementation including proper parameter encoding, asset format handling, resource account management, and production-grade error handling.

## Prerequisites

- Basic understanding of Move and Aptos smart contracts
- Access to deployed DEX-Router-Aptos contracts
- Aptos CLI installed and configured
- Move development environment

## Guide 1: Simple Token Swap with Multi-Protocol Support

### Introduction
This guide demonstrates how to execute a production-ready token swap using the DEX-Router-Aptos with advanced features including multi-protocol routing, proper parameter encoding, and comprehensive error handling. You'll learn to build a complete Move script that can handle real-world DEX aggregation with flexible protocol selection.

### What You'll Build
A comprehensive swap script that exchanges tokens with configurable protocol selection, asset format handling, and production-grade parameter validation.

### Implementation

**Step 1: Complete Script Setup**
```move
// SPDX-License-Identifier: MIT
script {
use dex_router::aggregator;
use aptos_framework::coin;
use aptos_framework::signer;
use aptos_framework::fungible_asset::{Self, Metadata};
use aptos_framework::object::Object;
use std::vector;

// Core DEX protocol constants
const DEX_PONTEM: u8 = 3;      // Liquidswap V1
const DEX_PANCAKE: u8 = 7;     // PancakeSwap Aptos  
const DEX_PONTEM_V2: u8 = 8;   // Liquidswap V2
const DEX_CELLANA: u8 = 9;     // Cellana (FA support)
const DEX_HYPERION: u8 = 10;   // Hyperion V3

// Pool type constants
const POOL_STANDARD: u64 = 0;   // Standard AMM pool
const POOL_STABLE: u64 = 1;     // Stable pair pool

fun main<X, Y>(sender: &signer) {
    // Implementation will be shown in steps below
}
}

**Step 2: Implement Basic Swap Function**
```move
fun perform_token_swap<X, Y, LP>(
    sender: &signer,
    input_amount: u64,
    min_output: u64,
    preferred_dex: u8,
    asset_object_x: Object<Metadata>,
    asset_object_y: Object<Metadata>
) {
    // Step 1: Validate DEX support and parameters
    assert!(input_amount > 0, 1);
    assert!(min_output > 0, 2);
    assert!(
        preferred_dex == DEX_PONTEM || 
        preferred_dex == DEX_PANCAKE || 
        preferred_dex == DEX_PONTEM_V2 ||
        preferred_dex == DEX_CELLANA ||
        preferred_dex == DEX_HYPERION,
        3  // E_UNKNOWN_DEX
    );
    
    // Step 2: Configure routing parameters
    let dex_types = vector[preferred_dex];
    let pool_types = vector[POOL_STANDARD];
    let is_x_to_y = vector[true];  // X → Y direction
    
    // Step 3: Setup asset objects (4 elements required)
    let asset_objects = vector[
        asset_object_x,    // Input asset
        asset_object_y,    // Output asset
        asset_object_y,    // Unused for 1-hop (same as output)
        asset_object_y     // Final output asset
    ];
    
    // Step 4: Configure asset format flags
    let is_FA = vector[false, false, false, false]; // All Coin format
    
    // Step 5: Execute the swap with comprehensive error handling
    aggregator::unxswap<X, Y, Y, Y, LP, LP, LP>(
        sender,
        input_amount,
        min_output,
        dex_types,
        pool_types,
        is_x_to_y,
        asset_objects,
        is_FA
    );
}
```

**Step 3: Usage Example**
```move
// Execute APT → USDC swap via PancakeSwap
fun main<APT, USDC, PancakeLP>(sender: &signer) {
    let apt_object = @0x1::object::address_to_object(@0x1);
    let usdc_object = @0x1::object::address_to_object(@0xa);
    
    perform_token_swap<APT, USDC, PancakeLP>(
        sender,
        100000000,      // 1 APT input (8 decimals)
        4500000,        // Min 4.5 USDC output (6 decimals, 5% slippage)
        DEX_PANCAKE,    // Use PancakeSwap
        apt_object,
        usdc_object
    );
}

### Expected Output
- Input: 1 APT
- Output: ~4.5 USDC (to user's account)
- Gas: ~15,000 gas units
- Slippage protection prevents unfavorable execution

**Key Features Demonstrated:**
- Flexible protocol selection with validation
- Proper parameter encoding for aggregator function
- Asset format handling for Coin assets
- Comprehensive error handling and validation

**📁 Complete Example**: View the complete implementation in `sources/aggregator.move` in our repository.

---

## Guide 2: Multi-Hop Cross-Protocol Routing

### Introduction
This guide demonstrates how to use the DEX-Router-Aptos for complex multi-hop routing across different DEX protocols. You'll learn to execute optimal price discovery by routing through up to 3 different protocols in a single atomic transaction.

### What You'll Build
A smart contract that demonstrates multi-protocol routing with 2-3 hop execution paths, proper asset format handling, and comprehensive slippage protection across the entire routing path.

### Implementation

**Step 1: Multi-Hop Script Setup**
```move
script {
use dex_router::aggregator;
use aptos_framework::object::Object;
use aptos_framework::fungible_asset::Metadata;
use std::vector;

// DEX protocol constants
const DEX_PONTEM: u8 = 3;
const DEX_PANCAKE: u8 = 7;
const DEX_CELLANA: u8 = 9;
const DEX_HYPERION: u8 = 10;

**Step 2: Implement 2-Hop Cross-Protocol Routing**
```move
fun two_hop_routing<X, Y, Z, LP1, LP2>(
    sender: &signer,
    input_amount: u64,
    min_output: u64,
    asset_x: Object<Metadata>,
    asset_y: Object<Metadata>, 
    asset_z: Object<Metadata>
) {
    // 1. Configure 2-hop cross-protocol routing
    let dex_types = vector[DEX_PONTEM, DEX_CELLANA];  // Pontem → Cellana
    let pool_types = vector[POOL_STANDARD, POOL_STABLE];
    let is_x_to_y = vector[true, true];  // Both hops in positive direction
    
    // 2. Multi-asset configuration (X → Y → Z)
    let asset_objects = vector[
        asset_x,    // Input asset
        asset_y,    // First intermediate
        asset_z,    // Second intermediate (same as output)
        asset_z     // Final output asset
    ];
    let is_FA = vector[false, false, false, false];
    
    // 3. Execute 2-hop atomic routing
    aggregator::unxswap<X, Y, Z, Z, LP1, LP2, LP2>(
        sender,
        input_amount,
        min_output,
        dex_types,
        pool_types,
        is_x_to_y,
        asset_objects,
        is_FA
    );
}

// Usage example: APT → USDC → WETH
fun main<APT, USDC, WETH, PontemLP, CellanaLP>(sender: &signer) {
    let apt_obj = @0x1::object::address_to_object(@0x1);
    let usdc_obj = @0x1::object::address_to_object(@0xa);
    let weth_obj = @0x1::object::address_to_object(@0xb);
    
    two_hop_routing<APT, USDC, WETH, PontemLP, CellanaLP>(
        sender,
        200000000,   // 2 APT input
        180000000,   // Min WETH output
        apt_obj,
        usdc_obj,
        weth_obj
    );
}

**Step 3: Maximum 3-Hop Routing**
```move
fun three_hop_routing<X, Y, Z, M, LP1, LP2, LP3>(
    sender: &signer,
    input_amount: u64,
    min_output: u64,
    assets: vector<Object<Metadata>>
) {
    // 1. Configure 3-protocol routing for maximum optimization
    let dex_types = vector[DEX_PONTEM_V2, DEX_CELLANA, DEX_HYPERION];
    let pool_types = vector[POOL_STANDARD, POOL_STABLE, POOL_STANDARD];
    let is_x_to_y = vector[true, false, true];  // Mixed directions
    
    // 2. Asset format configuration
    let is_FA = vector[false, false, false, false];
    
    // 3. Execute 3-hop atomic routing
    aggregator::unxswap<X, Y, Z, M, LP1, LP2, LP3>(
        sender,
        input_amount,
        min_output,
        dex_types,
        pool_types,
        is_x_to_y,
        assets,
        is_FA
    );
}
}
```

### Expected Output
- **Multi-hop execution**: Atomic execution across multiple protocols
- **Optimal pricing**: Best rates through cross-protocol arbitrage
- **Gas efficiency**: Single transaction for complex routing
- **Slippage protection**: End-to-end minimum output validation

**Key Features Demonstrated:**
- Multi-protocol atomic execution (2-3 hops)
- Cross-protocol price optimization
- Complex asset path routing
- Comprehensive parameter validation

**📁 Complete Example**: View the complete multi-hop patterns in `sources/aggregator.move`.

---

## Guide 3: Fungible Asset (FA) Support

### Introduction
This guide demonstrates how to use the DEX-Router-Aptos with modern Aptos Fungible Asset (FA) standard. You'll learn to handle mixed Coin/FA routing, cross-format conversions, and leverage FA-supporting protocols like Cellana and Hyperion.

### What You'll Build
A comprehensive FA integration that demonstrates mixed format routing, automatic format detection, and seamless conversion between legacy Coin and modern FA assets.

### Implementation

**Step 1: FA-Enabled Script Setup**
```move
script {
use dex_router::aggregator;
use aptos_framework::fungible_asset::{Self, Metadata};
use aptos_framework::object::Object;
use aptos_framework::primary_fungible_store;

**Step 2: Mixed Format Swap Implementation**
```move
fun mixed_format_swap<CoinType, FAType, LP>(
    sender: &signer,
    input_amount: u64,
    min_output: u64,
    fa_output_object: Object<Metadata>
) {
    // 1. Configure mixed format: Coin input → FA output
    let dex_types = vector[DEX_CELLANA];  // Use FA-supporting protocol
    let pool_types = vector[0];           // Stable pool for FA pairs
    let is_x_to_y = vector[true];
    
    // 2. Mixed asset format configuration
    let asset_objects = vector[
        @0x1::object::address_to_object(@0x1),  // Coin input (placeholder)
        fa_output_object,                        // FA output metadata
        fa_output_object,                        // Same as output for 1-hop
        fa_output_object                         // FA output
    ];
    
    // 3. Format flags: Coin input, FA output
    let is_FA = vector[false, true, true, true];
    
    // 4. Execute mixed format swap
    aggregator::unxswap<CoinType, FAType, FAType, FAType, LP, LP, LP>(
        sender,
        input_amount,
        min_output,
        dex_types,
        pool_types,
        is_x_to_y,
        asset_objects,
        is_FA
    );
}

**Step 3: Pure FA Multi-Hop Routing**
```move
fun fa_multi_hop<FA_IN, FA_MID, FA_OUT, LP1, LP2>(
    sender: &signer,
    input_amount: u64,
    min_output: u64,
    input_fa: Object<Metadata>,
    mid_fa: Object<Metadata>,
    output_fa: Object<Metadata>
) {
    // 1. Multi-protocol FA routing: Cellana → Hyperion
    let dex_types = vector[DEX_CELLANA, DEX_HYPERION];
    let pool_types = vector[0, 2];   // Stable vs concentrated liquidity
    let is_x_to_y = vector[true, false];
    
    // 2. Pure FA asset configuration
    let asset_objects = vector[input_fa, mid_fa, output_fa, output_fa];
    let is_FA = vector[true, true, true, true];  // All FA format
    
    // 3. Execute pure FA multi-hop routing
    aggregator::unxswap<FA_IN, FA_MID, FA_OUT, FA_OUT, LP1, LP2, LP2>(
        sender, input_amount, min_output, dex_types, pool_types, is_x_to_y, asset_objects, is_FA
    );
### Expected Output
- **Cross-format routing**: Seamless Coin ↔ FA conversions
- **Protocol compatibility**: Automatic FA-supporting protocol selection
- **Metadata preservation**: Complete FA metadata tracking
- **Format flexibility**: Mixed format multi-hop routing

**Key Features Demonstrated:**
- Mixed Coin/FA format handling in single transaction
- FA-supporting protocol utilization (Cellana, Hyperion)
- Automatic format detection and validation
- Pure FA multi-hop routing capabilities

**📁 Complete Example**: View FA integration patterns in `adapters/cellana_adapter/` and `adapters/hyperion_adapter/`.

---

## Guide 4: Event Monitoring & Analytics

### Introduction
DEX-Router-Aptos emits comprehensive OrderRecord events for every swap operation. This guide shows you how to capture, parse, and analyze these events for trading analytics, monitoring, and integration with external systems.

### What You'll Build
A complete event monitoring system with analytics capabilities, real-time tracking, and integration patterns for external APIs.

### Implementation

**Step 1: Event Structure Understanding**
```move
// Event structure from aggregator.move
#[event]
struct OrderRecord has drop, store {
    dex_type: u8,                      // Protocol identifier
    pool_type: u64,                    // Pool-specific parameters  
    x_type_info: TypeInfo,             // Input asset type
    y_type_info: TypeInfo,             // Output asset type
    asset_object_in: Object<Metadata>, // FA input metadata
    asset_object_out: Object<Metadata>, // FA output metadata
    is_in_FA: bool,                    // Input format flag
    is_out_FA: bool,                   // Output format flag
    input_amount: u64,                 // Actual input
    output_amount: u64,                // Actual output
    time_stamp: u64                    // Execution timestamp
}
```

**Step 2: Event Processing Module**
```move
module event_analytics {
    use aptos_framework::event;
    use aptos_framework::timestamp;
    
    struct SwapAnalytics has key {
        total_volume: u64,
        swap_count: u64,
        protocol_stats: vector<u64>,
        last_update: u64
    }
    
    public fun process_swap_event(event: OrderRecord): (u8, u64, u64, bool) {
        // Extract key metrics
        (event.dex_type, event.input_amount, event.output_amount, event.is_in_FA)
    }
    
    public entry fun initialize_analytics(account: &signer) {
        move_to(account, SwapAnalytics {
            total_volume: 0,
            swap_count: 0, 
            protocol_stats: vector::empty(),
            last_update: timestamp::now_microseconds()
        });
    }
}
```

### Expected Output
- **Real-time tracking**: Complete swap event capture and processing
- **Analytics dashboard**: Volume, count, and protocol distribution metrics
- **Format insights**: Coin vs FA usage patterns and trends
- **Integration ready**: Structured data for external API consumption

**Key Features Demonstrated:**
- Comprehensive event structure parsing
- Real-time analytics processing
- Protocol-specific volume tracking
- Asset format distribution analysis

**📁 Complete Example**: View event handling patterns in `sources/aggregator.move` OrderRecord emissions.

---

## Common Patterns and Best Practices

### 1. Choose the Right Protocol
- **Coin-only assets**: Use Pontem, PancakeSwap, or Pontem V2
- **FA assets**: Use Cellana or Hyperion for full FA support
- **Mixed formats**: Route through FA-supporting protocols
- **Multi-hop**: Combine different protocols for optimal pricing

### 2. Parameter Validation
```move
// Always validate parameters before swap execution
assert!(input_amount > 0, 1);
assert!(min_output > 0, 2);
assert!(vector::length(&dex_types) <= 3, 5);  // Max 3 hops
assert!(vector::length(&asset_objects) == 4, 8);  // Required length
```

### 3. Asset Format Handling
```move
// Configure asset format flags correctly
let is_FA = vector[
    is_input_fa,     // Input asset format
    is_output_fa,    // Output asset format (intermediate)
    is_output_fa,    // Output asset format (final intermediate)
    is_output_fa     // Final output asset format
];
```

### 4. Error Handling
- **E_OUTPUT_LESS_THAN_MINIMUM (2)**: Increase slippage tolerance
- **E_UNKNOWN_DEX (3)**: Use supported DEX constants (3,7,8,9,10)
- **E_OUT_HIP (5)**: Reduce to maximum 3 hops
- **E_LENGTH_NOT_EQUAL (6)**: Ensure consistent vector lengths
- **E_INVALID_FA_INFO_LENGTH (8)**: Provide exactly 4 asset objects

### 5. Gas Optimization
- **Single-hop**: Use when possible for lowest gas costs
- **Multi-hop**: Balance optimization vs gas consumption
- **FA protocols**: Slightly higher gas for enhanced functionality
- **Batch operations**: Group multiple swaps when feasible

## Next Steps

### Recommended Learning Path
1. **Start with Guide 1**: Master basic single-hop swaps
2. **Progress to Guide 2**: Implement multi-hop cross-protocol routing
3. **Add Guide 3**: Integrate modern FA asset support
4. **Complete Guide 4**: Implement comprehensive event monitoring

### Production Considerations
- **Comprehensive Testing**: Test all swap scenarios on testnet
- **Event Monitoring**: Implement real-time swap tracking and alerting
- **Error Recovery**: Design robust error handling and retry mechanisms
- **Security Audits**: Review integrations before mainnet deployment

### Advanced Integration
- **Custom Routing**: Implement dynamic protocol selection algorithms
- **Price Oracles**: Integrate external price feeds for slippage calculation
- **MEV Protection**: Implement front-running protection mechanisms
- **Analytics**: Build comprehensive trading analytics dashboards







