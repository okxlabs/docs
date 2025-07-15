# DEX-Router-Solana-V1 Overview

## What is DEX-Router-Solana-V1?

DEX-Router-Solana-V1 is a sophisticated DEX aggregation and routing system built on Solana that enables optimal token swapping across multiple decentralized exchanges (DEXs) and protocols. It acts as a unified interface for executing complex multi-path swaps, providing users with the best possible rates by splitting orders across different liquidity sources within the Solana ecosystem.

## Architecture Overview

The DEX-Router-Solana-V1 follows a modular architecture designed for extensibility and compute unit optimization:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User/DApp     │───▶│   DexRouter      │───▶│  Adapter Layer  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Commission & SOL │    │ DEX Protocols   │
                       │   Management     │    │ (80+ Supported) │
                       └──────────────────┘    └─────────────────┘
```

## High-Level Components

### Core Program
- **Program ID**: `6m2CDdhRgxpH4WjvdzxAYbGxwdGUz5MziiL5jek2kBma`
- **Framework**: Anchor v0.30.1
- **Features**: Smart routing, batch execution, commission handling, multi-protocol support

### Main Instructions

#### Core Swap Instructions
- **swap/swap2**: Basic token swapping with smart routing
- **swap_v3**: Advanced V3 swapping with enhanced features
- **proxy_swap**: Proxy-based swapping for complex routing scenarios

#### Commission-Based Instructions
- **commission_spl_swap/commission_spl_swap2**: SPL token swaps with commission handling
- **commission_sol_swap/commission_sol_swap2**: SOL/WSOL swaps with commission handling
- **commission_spl_from/to**: Directional SPL commission swaps
- **commission_sol_from**: SOL-based commission collection

#### Platform Fee Instructions
- **platform_fee_spl_from/to**: SPL token swaps with platform fee collection
- **platform_fee_sol_from/to**: SOL swaps with platform fee handling
- **platform_fee_wrap/unwrap**: Native token wrapping with platform fees
- **platform_fee_v2**: Enhanced platform fee collection system
- **us_platform_fee**: US-specific platform fee handling

#### Wrap/Unwrap Instructions
- **wrap_from/to_commission**: SOL wrapping with commission collection
- **unwrap_from/to_commission**: WSOL unwrapping with commission handling

#### Trim Instructions
- **trim_swap/trim_swap_v2**: Fee trimming and optimization for swaps

#### Protocol-Specific Adapters (80+ DEX Protocols)
- **Raydium**: raydium_launchpad and various Raydium pool types
- **Meteora**: meteora, meteora_dbc, meteora_dbc_2 variants
- **Whirlpool**: whirlpoolv2 concentrated liquidity
- **OpenBook**: openbookv2 orderbook integration
- **Phoenix**: phoenix orderbook DEX
- **Sanctum**: sanctum LST and sanctum-router
- **Perpetuals**: perpetuals protocol integration
- **Meme Platforms**: pumpfun, pumpfunamm, boopfun, virtuals
- **Additional DEXs**: aldrinv1, obricv2, solfi, stabble, saros, saros_dlmm, woofi, zerofi, qualia, vertigo, goosefx, gavel, dooar, numeraire, one_dex
- **Specialized**: saber_decimal_wrapper for decimal handling

### Base Swap Components
- **Common Swap Handler**: Core swap logic with multi-path execution
- **Commission System**: Integrated fee collection and distribution
- **Event System**: Comprehensive event emission for swap tracking and analytics
- **Proxy Swap**: Intermediate token account management for complex swaps

### Adapter Ecosystem
The router supports **80+ DEX Protocols** through dedicated adapter implementations:

#### Major Solana DEX Protocols
- **Raydium**: V1, V2, CLMM, CPMM, Stable, Launchpad adapters
- **Whirlpool**: V1 and V2 adapters
- **Meteora**: Dynamic pools, DLMM, DBC, Vault, LST adapters
- **Orca**: Direct pool interactions
- **Phoenix**: Orderbook-based DEX adapter
- **Sanctum**: LST staking and router adapters
- **OpenBook V2**: Orderbook trading adapter

#### Specialized Protocols
- **Meme Token Platforms**: Pumpfun, Pumpfunamm, Boopfun
- **Perpetuals**: JLP liquidity and swap adapters
- **Stablecoin Protocols**: Saber, Stabble, Stable swap
- **Cross-chain**: Bridge integrations
- **Derivatives**: Perpetuals, options protocols
- **Others**: 50+ additional Solana-native protocols

### Support Libraries
- **Token Utilities**: SPL Token and Token-2022 support
- **Math Libraries**: Precision calculations for swaps
- **Logging**: Comprehensive event and log emission
- **Account Management**: PDA and account creation utilities

## High-Level Functionality

### Smart Routing
- **Multi-path execution**: Split orders across multiple DEXs simultaneously
- **Batch processing**: Execute multiple swaps in a single transaction
- **Slippage protection**: Configurable minimum return amounts

### Swap Types

#### Basic Swaps
- **Concept**: Direct token-to-token swaps with smart routing
- **Use case**: "I want to swap 1000 USDC for as much SOL as possible"
- **Protection**: Minimum output amount (slippage protection)

#### Commission-based Swaps
- **Concept**: Swaps with built-in commission collection
- **Use case**: Platform integration with referral rewards
- **Protection**: Commission rate limits and validation

### Transaction Management
- **Order ID tracking**: Unique identifiers for swap operations
- **Event-driven architecture**: Comprehensive event emission for all operations
- **Commission integration**: Flexible fee collection system

### Advanced Features
- **Comprehensive instruction set**: 30+ specialized instruction types for different use cases
- **Multi-tier fee system**: Commission, platform fees, trim fees, and US compliance fees
- **Native token integration**: Advanced SOL/WSOL wrapping with fee handling
- **Event system**: Comprehensive event emission for analytics and monitoring
- **Multi-token support**: SPL Token and Token-2022 compatibility
- **Compute optimization**: Efficient instruction execution across all swap types
- **Account management**: Automatic PDA and associated token account creation
- **Global configuration**: Admin-controlled trading parameters and resolver management
- **Regional compliance**: US-specific instructions for regulatory compliance

### Supported Swap Types
1. **Multi-hop swaps**: Complex routing through multiple protocols
2. **Split swaps**: Divide orders across multiple paths
3. **Proxy swaps**: Intermediate account management for complex routes
4. **Commission swaps**: Built-in fee collection and distribution
5. **Platform fee swaps**: Integrated platform fee collection with various configurations
6. **Wrap/Unwrap operations**: Native SOL to WSOL conversion with fee handling
7. **US compliance swaps**: Region-specific fee handling and compliance features

## Contract Architecture

### Instruction System
The Solana program uses Anchor's instruction-based architecture:

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Client/SDK        │───▶│   Anchor Program     │───▶│   Adapter Layer     │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
                                    │                           │
                                    ▼                           ▼
                            ┌──────────────────────┐    ┌─────────────────────┐
                            │   State Management   │    │   DEX Protocols     │
                            │  (Config & Events)   │    │ (80+ Supported)     │
                            └──────────────────────┘    └─────────────────────┘
```

#### Architecture Features:
1. **Account-based Model**: Uses Solana's account model for efficient state management
2. **Compute Unit Optimization**: Optimized for Solana's compute unit limits
3. **PDA Management**: Automatic Program Derived Address creation and management
4. **Token Account Handling**: Automatic associated token account creation
5. **Rent Considerations**: Account rent and space optimization
6. **Stateless Processing**: No persistent order or position state - pure swap aggregation
7. **Event-driven**: Comprehensive event emission for all operations

## Source Code Location

### Repository Structure
```
programs/dex-solana/
├── src/
│   ├── lib.rs                   # Main program entry point
│   ├── instructions/            # Instruction handlers (30+ instruction types)
│   │   ├── swap.rs              # Basic swap instruction
│   │   ├── swap_v3.rs           # V3 enhanced swapping
│   │   ├── commission_swap.rs   # Commission-based swaps
│   │   ├── platform_fee_*.rs    # Platform fee instructions
│   │   ├── proxy_swap.rs        # Proxy swap handling
│   │   ├── *_wrap_unwrap.rs     # SOL/WSOL conversion instructions
│   │   ├── trim_swap*.rs        # Fee trimming instructions
│   │   ├── us_*.rs              # US compliance instructions
│   │   └── common_swap.rs       # Common swap logic
│   ├── adapters/                # 80+ DEX Protocol adapters
│   │   ├── raydium.rs           # Raydium adapter
│   │   ├── whirlpool.rs         # Whirlpool adapter
│   │   ├── meteora.rs           # Meteora adapter
│   │   └── ...                  # Other protocol adapters
│   ├── state/                   # State management
│   │   ├── event.rs             # Event definitions and emission
│   │   ├── config.rs            # Global configuration and admin management
│   │   └── mod.rs               # Module declarations
│   ├── utils/                   # Utility functions
│   ├── constants.rs             # Program constants
│   └── error.rs                 # Error definitions
├── Cargo.toml                   # Dependencies and configuration
└── Xargo.toml                   # Cross-compilation configuration
```

### Key Files
- **Main Program**: `src/lib.rs`
- **Core Swap Instructions**: `src/instructions/swap.rs`, `src/instructions/swap_v3.rs`
- **Commission Instructions**: `src/instructions/commission_*.rs`
- **Platform Fee Instructions**: `src/instructions/platform_fee_*.rs`
- **Wrap/Unwrap Instructions**: `src/instructions/*_wrap_unwrap.rs`
- **Specialized Instructions**: `src/instructions/proxy_swap.rs`, `src/instructions/trim_swap*.rs`
- **Adapter Interfaces**: `src/adapters/common.rs`
- **State Management**: `src/state/config.rs`, `src/state/event.rs`
- **Utilities**: `src/utils/` directory

## Event System

### Event-Driven Architecture
The DEX-Router-Solana-V1 includes a comprehensive event system for tracking all operations:

#### Core Events
- **Swap Events**: Track all swap operations across 30+ instruction types
- **Commission Events**: Monitor multi-tier fee collection and distribution
- **Platform Fee Events**: Track platform fee collection across various configurations
- **Wrap/Unwrap Events**: Monitor SOL/WSOL conversion operations
- **Trim Events**: Track fee optimization and cost reduction operations
- **Proxy Events**: Monitor complex routing through proxy swaps
- **Configuration Events**: Admin management and parameter updates

#### Event Features
- **Event-driven architecture**: All major operations emit events
- **Analytics support**: Detailed data for off-chain analysis

## Integration Guide

### Prerequisites
- **Solana CLI**: Version 1.18.20
- **Anchor Framework**: Version 0.30.1
- **Rust**: Latest stable version
- **Node.js**: For client SDK integration

### Program Information
- **Program ID**: `6m2CDdhRgxpH4WjvdzxAYbGxwdGUz5MziiL5jek2kBma`
- **Rent**: All accounts are rent-exempt
- **Compute Units**: Optimized for Solana's compute limits

### Development Setup
```bash
# Install Anchor
curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash

# Clone repository
git clone https://github.com/okxlabs/DEX-Router-Solana-V1.git
cd DEX-Router-Solana-V1

# Install dependencies
yarn install

# Build program
anchor build -p dex-solana

# Run node-proxy
cd node-proxy && cargo run --release
# Run tests
anchor test -p dex-solana
```

### Program Deployment

#### 1. Compile Contract
Ensure the contract is compiled with the latest code:
```bash
anchor build -p dex-solana
```

#### 2. Run Contract Tests
Verify no exceptions exist after compilation:
```bash
anchor test -p dex-solana
```

#### 3. Create Buffer Account
Create a temporary keypair as a buffer account for deployment:
```bash
solana-keygen new -o deploy_buffers.json
```

**Note**: Using buffer accounts prevents deployment failures due to network congestion by allowing resumed deployments from interruption points.

#### 4. Write Program Data to Buffer
```bash
solana program write-buffer ./target/deploy/dex_solana.so --buffer deploy_buffers.json -k <KEYPAIR_FILE_PATH>
```

#### 5. View Buffer Account Permissions
```bash
solana program show --buffers --buffer-authority <KEYPAIR_FILE_PATH>
```

#### 6. Transfer Buffer Authority
Transfer buffer account permissions to the target program authority:
```bash
solana program set-buffer-authority <BUFFER_ACCOUNT_ADDRESS> --new-buffer-authority <TARGET_PROGRAM_AUTHORITY> -k <KEYPAIR_FILE_PATH>
```

#### 7. Expand Contract Space (if needed)
When the new contract requires more space, expand the target contract first:
```bash
solana program extend <PROGRAM_ID> <SPACE> -k <KEYPAIR_FILE_PATH>
```

#### 8. Deploy Contract
Write buffer account data to the program address:
```bash
solana program deploy --program-id <PROGRAM_ID> --buffer <BUFFER_ADDRESS> -k <KEYPAIR_FILE_PATH>
```

### Integration Steps
1. **Install dependencies**: `yarn install`
2. **Build program**: `anchor build -p dex-solana`
3. **Test integration**: `anchor test -p dex-solana`
4. **Deploy using buffer**: Follow deployment steps above
5. **Client integration**: Use Anchor TypeScript SDK

## Network Support

The router system is designed for Solana's network infrastructure:
- **Mainnet Beta**: Production deployments.


## Security Features

- **Account validation**: Strict account ownership and signer checks
- **Minimum return validation**: Slippage protection on all trades
- **Commission rate limits**: Maximum commission rates to protect users
- **Compute unit optimization**: Efficient instruction execution
- **PDA security**: Secure Program Derived Address management

## Fee Structure & Token Support

### Fee Structure
- **Commission system**: Configurable referral and partner rewards
- **Platform fees**: Multi-tier platform fee collection with various configurations
- **Trim fees**: Fee optimization mechanisms for cost reduction
- **US compliance fees**: Region-specific fee handling for regulatory compliance
- **Directional fees**: Specialized fee collection for from/to swap patterns
- **Wrap/Unwrap fees**: Native token conversion with integrated fee collection

### Token Support
- **SPL Tokens**: Full SPL Token standard support
- **Token-2022**: Support for new token extensions
- **Native SOL**: Seamless SOL/WSOL handling

