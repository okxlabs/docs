# DEX-Router-EVM Overview

## What is DEX-Router-EVM?

DEX-Router-EVM is a sophisticated DEX aggregation and routing system that enables optimal token swapping across multiple decentralized exchanges (DEXs) and protocols. It acts as a unified interface for executing complex multi-path swaps, providing users with the best possible rates by splitting orders across different liquidity sources.

## Architecture Overview

The DEX-Router-EVM follows a modular architecture designed for extensibility and gas optimization:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User/DApp     │───▶│   DexRouter.sol  │───▶│  Adapter Layer  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Commission & ETH │    │ DEX Protocols   │
                       │    Management    │    │ (80+ Supported) │
                       └──────────────────┘    └─────────────────┘
```

## High-Level Components

### Core Router Contract
- **DexRouter.sol**: The main entry point contract that orchestrates all swap operations
- **Version**: v1.0.4-toB-commission
- **Features**: Smart routing, batch execution, commission handling, multi-protocol support

### ExactOut Router System
- **DexRouterExactOut.sol**: Specialized router for exact output swaps
- **Version**: v1.0.1
- **Features**: Exact output swap execution, commission handling, multi-protocol support

### Base Router Components
- **UnxswapRouter**: Handles Uniswap V2-style swaps with optimized routing
- **UnxswapV3Router**: Specialized for Uniswap V3 protocol interactions
- **UnxswapExactOutRouter**: Handles Uniswap V2-style exact output swaps
- **UnxswapV3ExactOutRouter**: Specialized for Uniswap V3 exact output swaps
- **WrapETHSwap**: Manages ETH/WETH wrapping and unwrapping operations
- **CommissionLib**: Implements commission fee collection and distribution

### Adapter Ecosystem
The router supports **80+ DEX protocols** through dedicated adapter contracts:

#### Major DEX Protocols
- **Uniswap**: V1, V2, V3 adapters
- **Pancakeswap**: V2 and V3 adapters
- **Curve**: Multiple curve variants (V2, StableNG, TNG, TriOpt)
- **Balancer**: V1, V2, and Composable adapters
- **1inch**: V1 and limit order adapters
- **DODO**: V1, V2, V3 adapters
- **SushiSwap**: Trident adapter
- **Kyber**: Classic and Elastic adapters

#### Specialized Protocols
- **Lending Protocols**: Aave V2/V3, Compound V2/V3
- **Yield Protocols**: Yearn, Pendle, Rocket Pool
- **Stablecoin Protocols**: Frax, DAI savings, stEUR
- **Cross-chain**: Multichain, Synapse
- **Derivatives**: GMX, Synthetix
- **Others**: 50+ additional protocols

### Support Libraries
- **SafeERC20**: Secure token transfers
- **UniversalERC20**: Unified ETH/ERC20 handling
- **TickMath**: Uniswap V3 mathematical operations
- **PMMLib**: Price-Making Market operations
- **CommonUtils**: Shared utility functions

## High-Level Functionality

### Smart Routing
- **Multi-path execution**: Split orders across multiple DEXs simultaneously
- **Batch processing**: Execute multiple swaps in a single transaction
- **Optimal pricing**: Find the best rates across all available liquidity sources
- **Slippage protection**: Configurable minimum return amounts

### Swap Types

#### Exact Input Swaps (Default)
- **Concept**: Specify exact amount of input tokens to swap
- **Use case**: "I want to swap exactly 1000 USDC for as much ETH as possible"
- **Protection**: Minimum output amount (slippage protection)
- **Implementation**: `DexRouter.sol` and related contracts

#### Exact Output Swaps
- **Concept**: Specify exact amount of output tokens to receive
- **Use case**: "I want to receive exactly 1 ETH and will pay up to 3000 USDC"
- **Protection**: Maximum input amount (cost protection)
- **Implementation**: `DexRouterExactOut.sol` and related contracts

### Transaction Management
- **Transaction ID tracking**: Unique identifiers for swap operations with memo support
- **DeadLine enforcement**: Time-based transaction expiration
- **Refund handling**: Automated refund of unused tokens for uniswapV3 pool
- **Commission integration**: Dual-rate fee collection system with referral support

### Advanced Features
- **Commission system**: Built-in referral and fee collection mechanism with dual-rate/bi-directional support
- **Memo functionality**: Brings arbitrary data onchain for reference without execution 
- **Pre-funded swaps**: Swaps using tokens already held in the router contract
- **Native token handling**: Seamless ETH/WETH conversion
- **Immutable design**: Decentralized operation without administrative controls
- **Gas optimization**: Efficient batch execution and path optimization

### Supported Swap Types
1. **Multi-hop swaps**: Complex routing through multiple protocols
2. **Split swaps**: Divide orders across multiple paths
3. **Pre-funded swaps**: Optimized for tokens already held in the router contract
4. **Exact output swaps**: Specify exact output amount with maximum input limit
5. **Unxswap**: Gas-efficient swaps between Uniswap V2-like pools with optimized routing
6. **Uniswap V3 swaps**: Gas-efficient swaps between Uniswap V3-like pools with optimized routing

## Contract Architecture

### Exact Output System
The exact output system provides specialized functionality for scenarios where users need to receive an exact amount of output tokens:

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   User/DApp         │───▶│ DexRouterExactOut.sol│───▶│   Direct Pool       │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
                                    │                           │
                                    ▼                           ▼
                            ┌──────────────────────┐    ┌─────────────────────┐
                            │ UnxswapExactOutRouter│    │ UnxswapV3ExactOut   │
                            │ UnxswapV3ExactOut    │    │ Router              │
                            │ Router               │    │                     │
                            └──────────────────────┘    └─────────────────────┘
```

#### Key Differences from Standard Router:
1. **Direct Pool Interaction**: Works directly with pools without adapter layer
2. **Input Calculation**: Calculates required input amount for desired output
3. **Reverse Path Execution**: Executes swaps in reverse order to achieve exact output
4. **Max Input Protection**: Prevents exceeding maximum input amount
5. **Commission Handling**: Adapted for exact output scenarios

## Source Code Location

### Repository Structure
```
DEX-Router-EVM/
├── contracts/8/
│   ├── DexRouter.sol                # Main router contract (exact input)
│   ├── DexRouterExactOut.sol        # ExactOut router contract
│   ├── UnxswapRouter.sol            # Uniswap V2 router (exact input)
│   ├── UnxswapV3Router.sol          # Uniswap V3 router (exact input)
│   ├── UnxswapExactOutRouter.sol    # Uniswap V2 exact output router
│   ├── UnxswapV3ExactOutRouter.sol  # Uniswap V3 exact output router
│   ├── adapter/                     # 80+ DEX adapters
│   │   ├── UniV3Adapter.sol
│   │   ├── PancakeswapV3Adapter.sol
│   │   ├── CurveAdapter.sol
│   │   └── ...
│   ├── interfaces/                  # Protocol interfaces
│   ├── libraries/                   # Utility libraries
│   └── utils/                       # Utility contracts
├── hardhat.config.js                # Hardhat configuration
├── foundry.toml                     # Foundry configuration
└── package.json                     # Dependencies
```

### Key Files
- **Main Contract**: `contracts/8/DexRouter.sol`
- **ExactOut Contract**: `contracts/8/DexRouterExactOut.sol`
- **Adapter Interfaces**: `contracts/8/interfaces/IAdapter.sol`
- **Commission Logic**: `contracts/8/libraries/CommissionLib.sol`
- **Utility Libraries**: `contracts/8/libraries/CommonUtils.sol`
- **ExactOut Routers**: `contracts/8/UnxswapExactOutRouter.sol`, `contracts/8/UnxswapV3ExactOutRouter.sol`

## Integration Guide

### Contract Deployment
The router system consists of multiple contracts that need to be deployed in sequence:

1. **Library contracts**: Deploy utility and commission libraries
2. **Adapter contracts**: Deploy protocol-specific adapters
3. **Main router**: Deploy the DexRouter with all dependencies

### Prerequisites
- **Solidity**: Version 0.8.17
- **Framework**: Hardhat development environment and Foundry development environment
- **Dependencies**: See `package.json` and `foundry.toml` for required packages

### Contract Addresses
Integration requires the following contract addresses:
- **DexRouter**: Main router contract address
- **ApproveProxy**: Token approval proxy contract
- **WNativeRelayer**: Native token wrapper contract
- **Adapter contracts**: Addresses for each supported DEX
- **Utility contracts**: Helper contracts for token handling

### Code Artifacts and Distribution
Currently, the DEX-Router-EVM is distributed as smart contract source code:
- **Source Code**: Available in this repository
- **Contract Deployments**: Deploy contracts to your target networks
- **No NPM Package**: This is a smart contract system, not a JavaScript library
- **Integration**: Direct smart contract interaction or ABI integration

### Integration Steps
1. **Install dependencies**: `npm install`
2. **Deploy contracts**: Use deployment scripts for contract deployment
3. **Configure adapters**: Set up adapter contracts for desired DEXs
4. **Test integration**: Verify swap functionality

### Development Setup
```bash
# Clone the repository
git clone https://github.com/okxlabs/DEX-Router-EVM-V1.git
cd DEX-Router-EVM-V1

# Install node_modules
npm install

# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test

# Deploy to network
forge script src/deploy/XXX.s.sol --rpc-url <rpc-url> --private-key <private-key> --broadcast
```

## Network Support

The router system is designed to work across multiple EVM-compatible networks:
- **Ethereum Mainnet**
- **Binance Smart Chain**
- **Polygon**
- **Arbitrum**
- **Avalanche**
- **And other EVM chains**

## Security Features

- **DeadLine checks**: All swaps must complete before specified deadLines
- **Minimum return enforcement**: Slippage protection on all trades
- **Immutable operations**: No administrative backdoors or privileged access
- **Secure token handling**: Using OpenZeppelin's SafeERC20
- **Reentrancy protection**: Built-in protection against reentrancy attacks

