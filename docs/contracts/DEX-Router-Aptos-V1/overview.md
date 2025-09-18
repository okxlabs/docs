# DEX-Router-Aptos-V1 Overview

## What is DEX-Router-Aptos-V1?

DEX-Router-Aptos-V1 is a sophisticated DEX aggregation and routing system built on Aptos that enables optimal token swapping across multiple decentralized exchanges (DEXs) and protocols. It acts as a unified interface for executing complex multi-path swaps, providing users with the best possible rates by splitting orders across different liquidity sources within the Aptos ecosystem.

## Architecture Overview

The DEX-Router-Aptos-V1 follows a modular architecture designed for extensibility and gas optimization:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User/DApp     │───▶│  aggregator.move │───▶│  Adapter Layer  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  router.move &   │    │ DEX Protocols   │
                       │  proxy.move      │    │ (5+ Supported)  │
                       └──────────────────┘    └─────────────────┘
```

## High-Level Components

### Core Router Contract
- **aggregator.move**: The main entry point contract that orchestrates all swap operations
- **Version**: v2.0.0
- **Features**: Smart routing, multi-hop execution, dual asset format support, comprehensive event emission, slippage protection
- **Package Address**: `0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1`

### Router Components
- **router.move**: Core routing logic for protocol selection and execution
- **proxy.move**: Manages resource account (PDA) for secure asset custody
- **Features**: PDA pattern implementation, automatic coin registration, permission isolation, gas optimization

### Adapter Ecosystem
The router supports **10+ DEX protocols** through dedicated adapter contracts:

#### Major Aptos DEX Protocols
- **Pontem Liquidswap**: V1 and V2 adapters for standard AMM pools
- **PancakeSwap**: Aptos version with V2-style AMM functionality  
- **Cellana Finance**: First-class Fungible Asset (FA) support with stable/volatile pools
- **Hyperion Protocol**: Concentrated liquidity V3-style with multiple fee tiers

#### Specialized Protocols
- **AnimeSwap**: Community-driven AMM with gaming integrations
- **Hippo Labs**: Advanced AMM with yield optimization
- **Econia Protocol**: Central limit order book (CLOB) integration
- **Basiq Protocol**: Multi-asset yield farming platform
- **Others**: Additional Aptos-native protocols

### Support Libraries
- **Aptos Framework**: Native coin and fungible asset management
- **Type System**: Type-safe generic programming for multi-asset support
- **Event System**: Comprehensive tracking and analytics capabilities
- **Vector Operations**: Efficient batch processing and parameter handling

## High-Level Functionality

### Smart Routing
- **Multi-path execution**: Split orders across multiple DEXs simultaneously
- **Multi-hop processing**: Execute up to 3-hop routing in a single transaction
- **Optimal pricing**: Find the best rates across all available liquidity sources
- **Slippage protection**: Configurable minimum return amounts
- **Enhanced error handling**: Custom error handling for better user experience

### Swap Types

#### Multi-Hop Swaps
- **Concept**: Execute complex routing paths across multiple protocols
- **Use case**: "I want to swap APT → USDC → WETH using Pontem and Cellana"
- **Protection**: Minimum output amount (slippage protection)
- **Implementation**: `aggregator.move` unxswap function

#### Asset Format Support
- **Legacy Coin Support**: Full backward compatibility with `Coin<T>` standard
- **Modern FA Integration**: Native support for Aptos Fungible Asset standard
- **Cross-Format Compatibility**: Seamless routing between different asset formats
- **Mixed Format Routing**: Route from Coin→FA, FA→Coin, or maintain format consistency

### Transaction Management
- **Resource Account (PDA)**: Secure intermediate asset custody using deterministic addresses
- **Automatic Registration**: Seamless coin registration and FA initialization  
- **Event Emission**: Comprehensive tracking with detailed OrderRecord events
- **Gas Optimization**: Efficient account reuse and batch processing

### Advanced Features
- **Comprehensive routing system**: Built-in multi-protocol aggregation and optimal path finding
- **Dual asset format support**: Seamless Coin and Fungible Asset integration with automatic format handling
- **Event-driven architecture**: Complete transaction tracking with detailed OrderRecord events
- **Resource Account pattern**: Secure intermediate asset custody using deterministic PDA addresses
- **Gas optimization**: Efficient batch processing and resource account reuse patterns
- **Production-ready error handling**: Custom error codes with detailed debugging information
- **Immutable design**: Decentralized operation without administrative controls

### Supported Swap Types
1. **Single-hop swaps**: Direct routing through optimal protocol
2. **Multi-hop swaps**: Complex routing through multiple protocols (up to 3 hops)
3. **Cross-format swaps**: Coin ↔ FA conversions with automatic handling
4. **Mixed protocol routing**: Leverage different DEX strengths in single transaction
5. **Batch execution**: Efficient processing of routing parameters

## Contract Architecture

### Multi-Protocol Routing System
The router system provides specialized functionality for multi-hop execution across different DEX protocols:

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   User/DApp         │───▶│   aggregator.move    │───▶│   Direct Protocol   │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
                                    │                           │
                                    ▼                           ▼
                            ┌──────────────────────┐    ┌─────────────────────┐
                            │    router.move       │    │   Adapter Layer     │
                            │    proxy.move        │    │   (Protocol         │
                            │                      │    │   Specific)         │
                            └──────────────────────┘    └─────────────────────┘
```

#### Key Differences from Single-Protocol Routing:
1. **Multi-Hop Execution**: Works across up to 3 different protocols in sequence
2. **Asset Format Flexibility**: Handles mixed Coin/FA routing seamlessly
3. **Resource Account Pattern**: Uses PDA for secure intermediate asset custody
4. **Event-Rich Tracking**: Emits detailed events for each hop with complete metadata
5. **Gas Optimization**: Efficient batch processing and automatic registration

## Source Code Location

### Repository Structure
```
DEX-Router-Aptos-V1/
├── Move.toml                 # Main package configuration
├── sources/
│   ├── aggregator.move       # Main entry point contract (348 lines)
│   ├── router.move          # Core routing logic (106 lines)
│   └── proxy.move           # PDA management (38 lines)
├── adapters/
│   ├── pontem_adapter/      # Liquidswap V1 integration
│   ├── pontem_adapter_v2/   # Liquidswap V2 integration
│   ├── pancake_adapter/     # PancakeSwap Aptos
│   ├── cellana_adapter/     # FA-ready Cellana integration
│   ├── hyperion_adapter/    # Concentrated liquidity V3
│   ├── anime_adapter/       # AnimeSwap (ready-to-deploy)
│   ├── hippo_adapter/       # Hippo Labs protocol
│   ├── econia_adapter/      # Econia order book
│   └── basiq_adapter/       # Basiq protocol
├── interface/
│   ├── pontem-Liquidswap/   # Pontem protocol interface
│   ├── cellana/             # Cellana protocol interface  
│   ├── hyperion/            # Hyperion protocol interface
│   └── pancake/             # PancakeSwap interface
├── scripts/
│   ├── config.ts            # Test configuration and constants
│   ├── testHelper.ts        # Testing utility functions
│   ├── util.ts              # General utilities
│   └── tests/
│       ├── singleHop.ts     # Single-hop swap tests
│       └── multiHop.ts      # Multi-hop routing tests
├── package.json             # TypeScript dependencies
├── tsconfig.json            # TypeScript configuration
└── README.md                # Project documentation
```

### Key Files
- **Main Contract**: `sources/aggregator.move`
- **Router Logic**: `sources/router.move`
- **PDA Management**: `sources/proxy.move`
- **Adapter Interfaces**: Individual adapter modules in `adapters/`
- **Protocol Interfaces**: Standard interfaces in `interface/` for protocol integration
- **Test Suite**: TypeScript test scripts in `scripts/tests/` for validation

## Integration Guide

### Contract Deployment
The router system consists of multiple Move modules that need to be deployed in sequence:

1. **Library contracts**: Deploy utility and commission libraries
2. **Adapter contracts**: Deploy protocol-specific adapters
3. **Main router**: Deploy the aggregator with all dependencies

### Prerequisites
- **Move Compiler**: Version 2.0+ with Aptos framework support
- **Aptos CLI**: Latest version for deployment and testing
- **Framework**: Aptos development environment
- **Dependencies**: See `Move.toml` for required packages

### Contract Addresses
Integration requires the following contract addresses:
- **Main Package**: `0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1`
- **Deployer Address**: `0xd2be0d7edad1cb3ecc9bee26bcfc3d595385e9fe309b115ca01e207bc234aefd`
- **Adapter contracts**: Addresses for each supported DEX
- **Utility contracts**: Helper contracts for asset handling

### Code Artifacts and Distribution
Currently, the DEX-Router-Aptos-V1 is distributed as Move source code:
- **Source Code**: Available in this repository
- **Contract Deployments**: Deploy contracts to your target networks
- **No NPM Package**: This is a Move smart contract system
- **Integration**: Direct smart contract interaction or SDK integration

### Integration Steps
1. **Install dependencies**: `npm install`
2. **Deploy contracts**: Use deployment scripts for contract deployment
3. **Configure adapters**: Set up adapter contracts for desired DEXs
4. **Test integration**: Verify swap functionality

### Development Setup
```bash
# Clone the repository
git clone https://github.com/okxlabs/DEX-Router-Aptos-V1.git
cd DEX-Router-Aptos-V1

# Install node_modules
npm install

# Install Aptos CLI (if not already installed)
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3

# Initialize Aptos account
aptos init --profile test_account

# Compile contracts
aptos move compile --package-dir .

# Run tests
aptos move test --package-dir .

# Deploy to testnet
aptos move publish --package-dir . --profile test_account

# Initialize the router
aptos move run --function-id package_address::proxy::init --profile test_account
```

## Network Support

The router system is designed to work across multiple Aptos networks:
- **Aptos Mainnet**
- **Aptos Testnet** 
- **Aptos Devnet**
- **Local Development Networks**

## Security Features

- **Resource Account Pattern**: All intermediate assets held in secure PDA with deterministic addressing
- **Minimum return enforcement**: Slippage protection on all trades
- **Enhanced error handling**: Custom error handling provides detailed error messages instead of generic failures
- **Immutable operations**: No administrative backdoors or privileged access
- **Secure asset handling**: Using Aptos Framework's native asset management with improved error reporting
- **Input validation**: Comprehensive parameter validation and bounds checking
- **Friend-only access**: Built-in protection with module-level access control 