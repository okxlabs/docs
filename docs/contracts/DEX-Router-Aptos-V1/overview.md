# DEX-Router-Aptos Overview

## What is DEX-Router-Aptos?

DEX-Router-Aptos is a sophisticated DEX aggregation and routing system that enables optimal token swapping across multiple decentralized exchanges (DEXs) and protocols on the Aptos blockchain. It acts as a unified interface for executing complex multi-path swaps, providing users with the best possible rates by splitting orders across different liquidity sources.

## Architecture Overview

The DEX-Router-Aptos follows a modular architecture designed for extensibility and gas optimization:

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
- **Features**: Multi-hop routing, dual asset format support, comprehensive event emission, slippage protection
- **Package Address**: `0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1`

### Multi-Hop Router System
- **router.move**: Core routing logic for protocol selection and execution
- **Version**: v2.0.0
- **Features**: Single-hop execution, asset format handling, adapter coordination, error propagation

### Resource Account Management
- **proxy.move**: Manages resource account (PDA) for secure asset custody
- **Features**: PDA pattern implementation, automatic coin registration, permission isolation, gas optimization

### Adapter Ecosystem
The router supports **5+ DEX protocols** with additional adapters ready for deployment:

#### Major DEX Protocols
- **Pontem Liquidswap**: V1 and V2 adapters for standard AMM pools
- **PancakeSwap**: Aptos version with V2-style AMM functionality  
- **Cellana Finance**: First-class Fungible Asset (FA) support with stable/volatile pools
- **Hyperion Protocol**: Concentrated liquidity V3-style with multiple fee tiers

#### Ready-to-Deploy Protocols
- **AnimeSwap**: Community-driven AMM with gaming integrations
- **Uniswap-style AMM**: V2/V3 compatible concentrated liquidity
- **Hippo Labs**: Advanced AMM with yield optimization
- **Econia Protocol**: Central limit order book (CLOB) integration
- **Basiq Protocol**: Multi-asset yield farming platform

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
- **Dual asset format**: Seamless routing between Coin and Fungible Asset formats

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
- **Modular Architecture**: Easy integration of new DEX protocols through adapter pattern
- **Version Management**: Support for multiple protocol versions (Pontem V1/V2)
- **Configuration Flexibility**: Vector-based routing with customizable parameters
- **Friend-Only Access**: Secure permission boundaries between modules
- **Production-Ready**: Battle-tested integrations with comprehensive error handling

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
LabsRepo/
├── Move.toml                 # Main package configuration
├── sources/
│   ├── aggregator.move       # Main entry point (347 lines)
│   ├── router.move          # Core routing logic (106 lines)
│   └── proxy.move           # PDA management (38 lines)
├── adapters/
│   ├── pontem_adapter/      # Liquidswap V1 integration
│   ├── pontem_adapter_v2/   # Liquidswap V2 integration
│   ├── pancake_adapter/     # PancakeSwap Aptos
│   ├── cellana_adapter/     # FA-ready Cellana integration
│   ├── hyperion_adapter/    # Concentrated liquidity V3
│   ├── anime_adapter/       # AnimeSwap (ready-to-deploy)
│   ├── uniswap_adapter/     # Uniswap-style AMM
│   ├── hippo_adapter/       # Hippo Labs protocol
│   ├── econia_adapter/      # Econia order book
│   └── basiq_adapter/       # Basiq protocol
└── interface/
    ├── pontem-Liquidswap/   # Pontem protocol interface
    ├── cellana/             # Cellana protocol interface  
    ├── hyperion/            # Hyperion protocol interface
    └── pancake/             # PancakeSwap interface
```

### Key Files
- **Main Contract**: `sources/aggregator.move`
- **Router Logic**: `sources/router.move`
- **PDA Management**: `sources/proxy.move`
- **Adapter Interfaces**: Individual adapter modules in `adapters/`
- **Protocol Interfaces**: Standard interfaces in `interface/` for protocol integration

## Integration Guide

### Contract Deployment
The router system consists of multiple Move modules that need to be deployed in sequence:

1. **Core modules**: Deploy aggregator, router, and proxy modules
2. **Adapter modules**: Deploy protocol-specific adapters
3. **Interface modules**: Deploy protocol interface definitions

### Prerequisites
- **Move Compiler**: Version 2.0+ with Aptos framework support
- **Aptos CLI**: Latest version for deployment and testing
- **Dependencies**: Aptos Framework mainnet version

### Contract Addresses
Integration requires the following package information:
- **Main Package**: `0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1`
- **Resource Account Seed**: `b"okx.dex.escrow.account.5"`
- **Deployer Address**: `0xd2be0d7edad1cb3ecc9bee26bcfc3d595385e9fe309b115ca01e207bc234aefd`

### Code Artifacts and Distribution
Currently, the DEX-Router-Aptos is distributed as Move source code:
- **Source Code**: Available in the main repository
- **Package Deployments**: Deploy to your target Aptos networks
- **No Cargo Package**: This is a Move smart contract system
- **Integration**: Direct Move function calls or transaction integration

### Integration Steps
1. **Install Aptos CLI**: `curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3`
2. **Clone repository**: Access the source code
3. **Compile contracts**: `aptos move compile --package-dir .`
4. **Deploy to testnet**: `aptos move publish --package-dir . --profile testnet`
5. **Test integration**: Verify swap functionality

### Development Setup
```bash
# Install Aptos CLI
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3

# Clone the repository
git clone <repository-url>
cd LabsRepo

# Compile Move contracts
aptos move compile --package-dir .

# Run tests
aptos move test --package-dir .

# Deploy to testnet
aptos move publish --package-dir . --profile testnet

# Example function call
aptos move run --function-id 0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1::aggregator::unxswap
```

## Network Support

The router system is designed to work across multiple Aptos networks:
- **Aptos Mainnet**
- **Aptos Testnet** 
- **Aptos Devnet**
- **Local Development Networks**

## Security Features

- **Resource Account Pattern**: All intermediate assets held in secure PDA with deterministic addressing
- **Slippage Protection**: All swaps must meet minimum output requirements with automatic reversion
- **Friend-Only Access**: Internal functions restricted to authorized modules only
- **Input Validation**: Comprehensive parameter validation and error handling
- **Asset Format Safety**: Automatic format detection and validation for Coin/FA compatibility
- **Event Transparency**: Complete transaction tracking with detailed metadata emission
- **Gas Optimization**: Efficient batch processing and resource account reuse patterns 