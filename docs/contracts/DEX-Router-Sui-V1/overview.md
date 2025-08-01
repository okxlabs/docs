# DEX Router - Overview

## Introduction

The **DEX Router** is a comprehensive integration platform for the Sui blockchain that provides unified access to multiple DeFi protocols through two complementary contracts. Due to Sui Move dependency limitations, the system is split into Router and Extended Router, designed to work together in Programmable Transaction Blocks (PTBs) for complete DeFi protocol coverage.

**Key Benefits:**
- **Complete Protocol Coverage**: Comprehensive DeFi protocols across two complementary contracts
- **PTB Integration**: Seamlessly combine both routers in single Programmable Transaction Block
- **Dependency-Optimized Design**: Split architecture overcomes Sui Move dependency limitations
- **Commission System**: Built-in referral rewards up to 3% for partners
- **Production Ready**: Both routers live on Sui mainnet with proven reliability

**Supported Blockchain:** Sui Network (mainnet)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          DEX Router System                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐                    ┌─────────────────────────┐ │
│  │     Router      │                    │   Extended Router       │ │
│  │   (Production)  │                    │   (Production)          │ │
│  │                 │                    │                         │ │
│  │ • Router        │                    │ • Extended Router       │ │
│  │ • Swap Functions│                    │ • Swap Functions        │ │
│  │ • Mainnet Live  │                    │ • Mainnet Live          │ │
│  └─────────────────┘                    └─────────────────────────┘ │
│           │                                        │                │
│           │                                        │                │
│  ┌────────▼────────────────────────────────────────▼──────────────┐ │
│  │                 Router Core Engine                             │ │
│  │                                                                │ │
│  │ • Swap Execution Logic     • Commission Processing             │ │
│  │ • Slippage Protection      • Event Emission                    │ │
│  │ • Error Handling           • Zero-Coin Cleanup                 │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                   │                                 │
│  ┌────────────────────────────────▼───────────────────────────────┐ │
│  │                     External DeFi Protocols                   │ │
│  │                                                                │ │
│  │  AFSUI • Aftermath • BlueMove • Cetus • DeepBook            │ │
│  │  FlowX • Kriya • MovePump • SuiSwap • Turbos               │ │
│  │  AlphaFi • BlueFin • Haedal • Momentum • Scallop           │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

        ┌─────────────────────────────────────────────────────┐
        │            Combined Router Usage Example             │
        │                                                     │
        │  PTB {                                              │
        │    1. Call Router (Cetus CLMM)                     │
        │    2. Call Extended Router (Haedal Staking)         │
        │    3. Chain outputs for complex strategies          │
        │  }                                                  │
        └─────────────────────────────────────────────────────┘
```

## High-Level Components

### Router Contracts

> **Design Note**: Due to Sui Move dependency limitations, the DEX Router system is split into two complementary contracts that work together in PTB transactions for complete protocol coverage.

**Router Contract** (`dexrouter`)
- **Version**: v1.1.2
- **Status**: Production (Mainnet Live)
- **Framework**: Sui Move v1.48.2
- **Functions**: Comprehensive swap functions across protocols

**Extended Router Contract** (`dexrouter_extended`)
- **Version**: v1.1.2
- **Status**: Production (Mainnet Live)
- **Framework**: Sui Move v1.48.2
- **Functions**: Comprehensive swap functions across protocols

### Router Core Components

**Swap Execution Engine**
- **Return Format**: Consistent `(Coin<T>, u64)` return for chaining
- **Direction Support**: Complete a2b (A-to-B) and b2a (B-to-A) coverage
- **Error Handling**: 11 specific error codes for different scenarios

**Commission Management System**
- **Rate Limits**: Maximum 3% (300 basis points) commission
- **Address Validation**: Automatic validation of referral addresses
- **Percentage Splitting**: Commission calculation based on rates within the contract
- **Event Tracking**: Commission records for analytics

**Event System**
- **OrderRecord**: Track transaction outcomes with order_id and amounts
- **CommissionRecord**: Monitor referral commission distribution
- **HopRecord**: Individual step tracking for multi-hop routes

## High-Level Functionality

### Swap Types

**Exact Input Swaps**
- **Definition**: User specifies exact input amount, receives variable output
- **Implementation**: All swap functions support exact input semantics
- **Use Case**: Standard trading where users know exact sell amount
- **Protection**: Minimum output guarantees prevent slippage exploitation

**Protocol-Specific Features**
- **CLMM Integration**: Concentrated liquidity with tick-based pricing
- **Stable Swaps**: Low-slippage trading for correlated assets
- **Liquid Staking**: SUI ↔ Staked SUI conversions
- **Lending Integration**: Supply/withdraw operations

### Safety Mechanisms

**Input Validation**
- **Amount Verification**: Non-zero amount requirements
- **Address Validation**: Proper recipient and referral address checks
- **Commission Limits**: Maximum rate enforcement
- **Type Safety**: Move language type system prevents runtime errors

**Transaction Safety**
- **Slippage Protection**: Minimum output amount validation
- **Resource Management**: Automatic cleanup of zero-value coins
- **Error Recovery**: Comprehensive error codes for debugging

### Commission System

**Referral Rewards**
- **Rate Structure**: Up to 3% commission for partners
- **Automatic Distribution**: Real-time commission calculation and transfer
- **Event Tracking**: Complete commission audit trail
- **Flexible Configuration**: Per-transaction commission rate setting

**Advanced Features**
- **Order Tracking**: Built-in order_id system for external tracking
- **Decimal Support**: Proper decimal precision tracking
- **Event Integration**: Standardized event emission for monitoring

## Contract Architecture

The DEX Router system consists of two production-ready smart contracts deployed on Sui mainnet, each handling specific protocol integrations to overcome Sui Move dependency limitations.

### Router Contract
**Package ID**: `0x3b79de9a1f64fed053481f0682b272cdc4ca7ae849699d594cb362b05afe4a2f`

**Integrated Protocols (13 total):**
- **AFSUI** - Liquid staking integration
- **Aftermath** - Advanced AMM
- **BlueMove** - Multi-curve AMM (regular + stable swaps)
- **Cetus** - Concentrated liquidity market maker
- **DeepBook** - Central limit order book
- **FlowX v2/v3** - Multi-version DEX integration
- **Kriya AMM/CLMM** - Dual protocol integration
- **MovePump** - Meme token trading protocol
- **SuiSwap** - Native Sui AMM
- **Turbos** - High-performance concentrated liquidity

### Extended Router Contract
**Package ID**: `0xe810da8bfdec2629a5b78fdd279db943fc1ced2281de3e63f8f7f0588d515ae2`

**Integrated Protocols (5 total):**
- **AlphaFi** - Advanced liquid staking and yield farming
- **BlueFin** - Professional spot trading
- **Haedal** - Liquid staking (SUI → haSUI)
- **Momentum** - Next-generation CLMM
- **Scallop** - Lending and borrowing market

### Architecture Design
Both contracts share the same core architecture pattern:
- **Swap Functions** - Protocol-specific swap implementations
- **Commission System** - Built-in referral rewards up to 3%
- **Event Emission** - Transaction tracking and analytics
- **PTB Integration** - Seamless Programmable Transaction Block support
- **Type Safety** - Full Sui Move type system integration

## Source Code Location

```
LabsRepo/
├── dexrouter/                     # Router (Production)
│   ├── Move.toml                  # Package configuration
│   └── sources/router.move        # Core routing logic (989 lines)
├── dexrouter-extended/            # Extended Router (Production)
│   ├── Move.toml                  # Package configuration
│   └── sources/router.move        # Advanced routing logic (584 lines)
└── interfaces/                    # Protocol Interface Definitions
    ├── aftermath/amm/             # Aftermath AMM integration
    ├── afsui/                     # AFSUI liquid staking
    ├── alphafi/                   # AlphaFi liquid staking
    ├── bluefin/                   # BlueFin spot trading
    ├── bluemove/                  # BlueMove AMM
    ├── cetus/                     # Cetus CLMM
    ├── deepbookV3/                # DeepBook order book
    ├── flowx/v2/                  # FlowX v2 DEX
    ├── flowxv3/                   # FlowX v3 CLMM
    ├── haedal/                    # Haedal liquid staking
    ├── kriya/amm/                 # Kriya AMM
    ├── kriya/clmm/                # Kriya CLMM
    ├── momentum/mmt_v3/           # Momentum v3
    ├── movepump/                  # MovePump integration
    ├── scallop/                   # Scallop lending
    ├── suiswap/                   # SuiSwap DEX
    └── turbos/                    # Turbos CLMM
```

## Technical Details

### Programming Language and Platform
- **Language**: Sui Move 
- **Framework**: Sui Framework v1.48.2
- **Compiler**: Move compiler with Sui extensions
- **Type System**: Full Move generics with Sui object model integration

### Deployment Information

**Router (Production)**
- **Package ID**: `0x3b79de9a1f64fed053481f0682b272cdc4ca7ae849699d594cb362b05afe4a2f`
- **Network Support**: Mainnet (Live)
- **Gas Optimization**: Production-tuned for minimal gas consumption

**Extended Router (Production)**
- **Package ID**: `0xe810da8bfdec2629a5b78fdd279db943fc1ced2281de3e63f8f7f0588d515ae2`
- **Network Support**: Mainnet (Live)

### Supported Protocols and Pools

**Router Protocol Support**
- **AFSUI**: Liquid staking integration
- **Aftermath**: Advanced AMM
- **BlueMove**: Multi-curve AMM (regular + stable swaps)
- **Cetus**: Concentrated liquidity market maker
- **DeepBook**: Central limit order book
- **FlowX v2/v3**: Multi-version DEX integration
- **Kriya AMM/CLMM**: Dual protocol integration
- **MovePump**: Meme token trading protocol
- **SuiSwap**: Native Sui AMM
- **Turbos**: High-performance concentrated liquidity

**Extended Router Protocol Support**
- **AlphaFi**: Advanced liquid staking and yield farming
- **BlueFin**: Professional spot trading
- **Haedal**: Liquid staking (SUI → haSUI)
- **Momentum**: Next-generation CLMM
- **Scallop**: Lending and borrowing market

## Quick Start

### Installation
```bash
npm install @mysten/sui.js dotenv
```

### Basic Swap Example
```typescript
import { TransactionBlock, SUI_CLOCK_OBJECT_ID, Connection, JsonRpcProvider, Ed25519Keypair, RawSigner } from '@mysten/sui.js';

// Setup connection and wallet
const connection = new Connection({ fullnode: "https://sui-rpc.publicnode.com" });
const provider = new JsonRpcProvider(connection);
const keypair = Ed25519Keypair.fromSecretKey(privateKey);
const signer = new RawSigner(keypair, provider);

// Contract addresses
const ROUTER_PACKAGE = "0x3b79de9a1f64fed053481f0682b272cdc4ca7ae849699d594cb362b05afe4a2f";
const GLOBAL_CONFIG = "0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f";
const POOL = "0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630";

// Create transaction
const txb = new TransactionBlock();
const amount = 10000;
const inputCoin = txb.splitCoins(txb.gas, [txb.pure(amount.toString())]);

// Execute swap
const [outputCoin] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::cetus_swap_b2a_with_return`,
    arguments: [
        txb.object(GLOBAL_CONFIG),
        txb.object(POOL),
        txb.makeMoveVec({ objects: [inputCoin] }),
        txb.pure(true),
        txb.pure(amount),
        txb.pure(0), // min_amount
        txb.pure(BigInt("79226673515401279992447579055")),
        txb.object(SUI_CLOCK_OBJECT_ID),
        txb.pure(0), // commission_rate
        txb.pure(6), // input_decimal
    ],
    typeArguments: ["0x...::coin::COIN", "0x2::sui::SUI"] // USDC, SUI
});

// Finalize
txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::finalize`,
    arguments: [
        outputCoin,
        txb.pure(1),
        txb.pure(0),
        txb.object(await signer.getAddress()),
        txb.object(await signer.getAddress()),
        txb.pure(0),
        txb.pure(9),
    ],
    typeArguments: ["0x2::sui::SUI"]
});

// Execute transaction
const result = await signer.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEffects: true }
});
```

---

*For comprehensive implementation guides and detailed API reference, see the accompanying guides.md and technical-reference.md documentation.* 