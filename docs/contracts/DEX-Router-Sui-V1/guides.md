# DEX-Router-Sui Implementation Guides

## Getting Started

These guides provide **step-by-step** implementation examples for the DEX-Router-Sui system. Each guide focuses on a single concept.

**💡 Real Implementation Examples**: All code examples are derived from working test implementations under `script/test/`.

## 🗺️ Essential Learning Path

```
🎯 Essential Guides | Total = 3 Core Patterns

Guide 1 ────▶ Guide 2 ────▶ Guide 3
Basic Swap   Commission    Advanced
Integration  System        Routing
```

**📋 Essential Integration Guides**:
- **Guide 1**: Basic Swap Integration *(Single protocol CLMM)*
- **Guide 2**: Commission System *(Fee collection & referral rewards)*
- **Guide 3**: Advanced Routing *(Multi-protocol sequential split)*

## Prerequisites

- Node.js 18+ and npm/yarn
- Basic understanding of Sui blockchain and TypeScript
- Access to Sui RPC endpoint
- **All patterns follow exact test cases from `script/test/`**

---

## Guide 1: Basic Swap Integration

### What You'll Build
Use `cetus_swap_b2a_with_return` for basic CLMM integration with the exact pattern from test.

### Quick Setup
```typescript
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { SuiClient } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui.js/utils";
import * as dotenv from "dotenv";

// Constants (from swap test - Note: Contract addresses may be updated)
const ROUTER_PACKAGE = "0xafff5502633f670a64328813b66fa08bc7a642ac9c81ed6c4b7ec5448e3b23ad";
const GLOBAL_CONFIG = "0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f";
const POOL = "0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630";

// Token types
const USDC_TYPE = "0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN";
const SUI_TYPE = "0x2::sui::SUI";
```

### Environment Setup
```typescript
// Environment validation (following swap test pattern)
const PRIVATE_KEY_STR = process.env.PRIVATE_KEY_STR;
if (!PRIVATE_KEY_STR) {
    throw new Error("PRIVATE_KEY_STR environment variable is required");
}

// Private key processing
const PRIVATE_KEY = Buffer.from(PRIVATE_KEY_STR, "base64").subarray(1);

// Provider and wallet initialization
const provider = new SuiClient({
    url: "https://sui-rpc.publicnode.com"
});

const keypair = Ed25519Keypair.fromSecretKey(PRIVATE_KEY);
const walletAddress = keypair.getPublicKey().toSuiAddress();
```

### Implementation
```typescript
// Basic Cetus swap configuration
const txb = new TransactionBlock();
const swapAmount = 10000; // 0.00001 SUI
const gasBudget = 4051120;

txb.setGasBudget(gasBudget);

// Prepare input coin
const amountCoin = txb.splitCoins(
    txb.gas,
    [txb.pure(swapAmount.toString())]
);

// Execute swap using router (exact pattern from test)
const [outputCoin] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::cetus_swap_b2a_with_return`,
    arguments: [
        txb.object(GLOBAL_CONFIG),              // config
        txb.object(POOL),                       // pool
        txb.makeMoveVec({ objects: [amountCoin] }), // coins
        txb.pure(true),                         // is_exact_in
        txb.pure(swapAmount),                   // amount
        txb.pure(0),                            // min_amount_out
        txb.pure(BigInt("79226673515401279992447579055")), // sqrt_price_limit
        txb.object(SUI_CLOCK_OBJECT_ID),        // clock
        txb.pure(0),                            // fee_rate
        txb.pure(6),                            // USDC decimals
    ],
    typeArguments: [USDC_TYPE, SUI_TYPE]
});

// Finalize transaction (required for all swaps)
txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::finalize`,
    arguments: [
        outputCoin,                             // input_coin
        txb.pure(1),                            // min_amount
        txb.pure(0),                            // commission_rate
        txb.pure(walletAddress),                // referral_address
        txb.pure(walletAddress),                // receiver_address
        txb.pure(0),                            // order_id
        txb.pure(6),                            // decimal
    ],
    typeArguments: [USDC_TYPE]
});

// Set transaction sender
txb.setSender(walletAddress);

// Build and execute transaction
const builtTx = await txb.build({ client: provider });
const result = await provider.dryRunTransactionBlock({
    transactionBlock: builtTx,
});
```

### Result
✅ Basic Cetus CLMM swap integration (exact pattern from test)  
✅ SUI → USDC conversion capability

### Next: [Guide 2 - Commission System](#guide-2-commission-system)

---

## Guide 2: Commission System

### What You'll Build
Use `split_with_percentage_for_commission` for fee collection with the exact pattern from commission test.

### Fee Configuration
```typescript
// Commission setup (following commission test pattern)
const commissionRate = 0; // Commission rate, 0 means no commission fee
const swapAmount = 0.1 * 10 ** 9; // 0.1 SUI in mist
const gasBudget = 10000000;

// Pool addresses (from commission test)
const CETUS_POOL = "0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630"; // USDC/SUI
const CETUS_CONFIG = "0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f";
const TURBOS_POOL = "0x5eb2dfcdd1b15d2021328258f6d5ec081e9a0cdcfa9e13a0eaeb9b5f7505ca78"; // SUI/USDC

// Fee type for Turbos
const FEE_TYPE = "0x91bfbc386a41afcfd9b2533058d7e915a1d3829089cc268ff4333d54d6339ca1::fee3000bps::FEE3000BPS";
const TURBOS_VERSIONED = "0xf1cf0e81048df168ebeb1b8030fad24b3e0b53ae827c25053fff0779c1445b6f";
```

### Implementation
```typescript
const txb = new TransactionBlock();
txb.setGasBudget(gasBudget);

// Prepare input coin
const inputCoin = txb.splitCoins(
    txb.gas,
    [txb.pure(swapAmount.toString())]
);

// Step 1: Split with percentage for commission (exact pattern from test)
const [remainingCoin, remainingCoinValue] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::split_with_percentage_for_commission`,
    arguments: [
        inputCoin,                              // input coin
        txb.pure(commissionRate),               // 0% commission
        txb.pure(walletAddress),                // commission recipient
    ],
    typeArguments: [SUI_TYPE]
});

// Transfer original input coin to recipient
txb.transferObjects([inputCoin], txb.pure(walletAddress));

// Step 2: Split remaining coin with percentage (50% split)
const [splitCoin, splitCoinValue, leftCoin, leftCoinValue] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::split_with_percentage`,
    arguments: [
        remainingCoin,                          // input coin
        txb.pure(5000)                          // 50% (5000/10000)
    ],
    typeArguments: [SUI_TYPE]
});

// Transfer remaining coin to recipient
txb.transferObjects([remainingCoin], txb.pure(walletAddress));

// Step 3: Parallel SUI → USDC Swaps
// Cetus swap - SUI to USDC (50% of remaining)
const [cetusOut, cetusAmount] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::cetus_swap_b2a_with_return`,
    arguments: [
        txb.object(CETUS_CONFIG),               // config
        txb.object(CETUS_POOL),                 // pool
        txb.makeMoveVec({ objects: [splitCoin] }), // coins
        txb.pure(true),                         // by_amount_in
        splitCoinValue,                         // amount
        txb.pure(0),                            // amount_limit
        txb.pure(BigInt("79226673515401279992447579055")), // sqrt_price_limit
        txb.object(SUI_CLOCK_OBJECT_ID),        // clock
        txb.pure(0),                            // order_id
        txb.pure(6),                            // USDC decimal
    ],
    typeArguments: [USDC_TYPE, SUI_TYPE]
});

// Turbos swap - SUI to USDC (50% of remaining)
const [turbosOut, turbosAmount] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::turbos_swap_a_b_with_return`,
    arguments: [
        txb.object(TURBOS_POOL),                // pool
        txb.makeMoveVec({ objects: [leftCoin] }), // coins
        leftCoinValue,                          // amount
        txb.pure(0),                            // amount_limit
        txb.pure(4295048017),                   // sqrt_price_limit
        txb.pure(true),                         // by_amount_in
        txb.pure(walletAddress),                // referral
        txb.pure(1816360958068),                // deadline
        txb.object(SUI_CLOCK_OBJECT_ID),        // clock
        txb.object(TURBOS_VERSIONED),           // versioned
        txb.pure(0),                            // order_id
        txb.pure(9),                            // SUI decimal
    ],
    typeArguments: [SUI_TYPE, USDC_TYPE, FEE_TYPE]
});

// Step 4: Merge and finalize
txb.setSender(walletAddress);

// Merge coins from both swaps
txb.mergeCoins(cetusOut, [turbosOut]);

// Standard finalize call
txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::finalize`,
    arguments: [
        cetusOut,                               // input_coin
        txb.pure(1),                            // min_amount
        txb.pure(0),                            // commission_rate
        txb.pure(walletAddress),                // referral_address
        txb.pure(walletAddress),                // receiver_address
        txb.pure(0),                            // order_id
        txb.pure(6),                            // USDC decimal
    ],
    typeArguments: [USDC_TYPE]
});

// Build and execute transaction
const builtTx = await txb.build({ client: provider });
const result = await provider.dryRunTransactionBlock({
    transactionBlock: builtTx
});
```

### Result
✅ Commission system with percentage splitting (exact pattern from test)  
✅ Multi-protocol parallel execution with fee collection

### Next: [Guide 3 - Advanced Routing](#guide-3-advanced-routing)

---

## Guide 3: Advanced Routing

### What You'll Build
Use sequential split strategy for complex multi-protocol routing with the exact pattern from multihop test.

### Advanced Configuration
```typescript
// Enhanced routing structure: sequential split with multi-hop (following multihop test pattern)
const totalAmount = 0.1 * 10 ** 9; // 0.1 SUI in mist
const gasBudget = 10000000;

// Multi-protocol pool addresses (from multihop-sequential-split test)
const CETUS_USDT_POOL = "0x..."; // SUI → USDT direct
const FLOWX_V3_CONFIG = "0x..."; // FlowX V3 config
const FLOWX_V3_POOL = "0x...";   // SUI → USDC via FlowX V3
const KRIYA_AMM_POOL = "0x...";  // USDC → USDT via Kriya AMM
const SUISWAP_POOL = "0x...";    // USDC → USDT via SuiSwap

// Token types
const USDT_TYPE = "0x...::coin::COIN"; // USDT token type
const USDT_DECIMAL = 6;
```

### Sequential Split Implementation
```typescript
/**
 * Sequential Split Strategy (exact pattern from multihop-sequential-split.ts)
 * 
 * Flow Diagram:
 * 100% SUI
 * ├── 40% → Cetus (SUI → USDT) ──────────────────────────┐
 * ├── 60% → FlowX V3 (SUI → USDC) ──┐                    │
 * │                                  ├─→ 20% KriyaAMM (USDC → USDT) ──┤
 * │                                  └─→ 80% SuiSwap (USDC → USDT) ───┤
 * │                                                            │
 * └───────────────────────────────────────────────────────────┘
 *                                                          100% USDT
 */

const txb = new TransactionBlock();
txb.setGasBudget(gasBudget);

// Initial coin preparation
const inputCoin = txb.splitCoins(
    txb.gas,
    [txb.pure(totalAmount.toString())]
);

// Step 1: Split into two main paths (40% and 60%)
const [path1Coin, path1Value, path2Coin, path2Value] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::split_with_percentage`,
    arguments: [
        inputCoin,                              // input coin
        txb.pure(4000)                          // 40% (4000/10000)
    ],
    typeArguments: [SUI_TYPE]
});

// Path 1: Direct SUI → USDT via Cetus (40%)
const [cetusOut, cetusAmount] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::cetus_swap_b2a_with_return`,
    arguments: [
        txb.object(CETUS_CONFIG),
        txb.object(CETUS_USDT_POOL),
        txb.makeMoveVec({ objects: [path1Coin] }),
        txb.pure(true),                         // by_amount_in
        path1Value,                             // amount
        txb.pure(0),                            // amount_limit
        txb.pure(BigInt("79226673515401279992447579055")), // sqrt_price_limit
        txb.object(SUI_CLOCK_OBJECT_ID),        // clock
        txb.pure(0),                            // order_id
        txb.pure(USDT_DECIMAL),                 // decimal
    ],
    typeArguments: [USDT_TYPE, SUI_TYPE]
});

// Path 2: SUI → USDC via FlowX V3 (60%)
const [flowxOut, flowxAmount] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::flowx_v3_swap_b2a_with_return`,
    arguments: [
        txb.object(FLOWX_V3_CONFIG),            // config
        txb.object(FLOWX_V3_POOL),              // pool
        txb.makeMoveVec({ objects: [path2Coin] }), // coins
        txb.pure(true),                         // by_amount_in
        path2Value,                             // amount
        txb.pure(0),                            // amount_limit
        txb.pure(4295048016),                   // sqrt_price_limit
        txb.object(SUI_CLOCK_OBJECT_ID),        // clock
        txb.pure(0),                            // order_id
        txb.pure(6),                            // USDC decimal
    ],
    typeArguments: [USDC_TYPE, SUI_TYPE]
});

// Sub-split Path 2 output: 20% and 80%
const [subPath1, subPath1Value, subPath2, subPath2Value] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::split_with_percentage`,
    arguments: [
        flowxOut,                               // USDC from FlowX
        txb.pure(2000)                          // 20% (2000/10000)
    ],
    typeArguments: [USDC_TYPE]
});

// Sub-path 1: USDC → USDT via Kriya AMM (20% of 60%)
const [kriyaOut, kriyaAmount] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::kriya_amm_swap_b2a_with_return`,
    arguments: [
        txb.object(KRIYA_AMM_POOL),             // pool
        txb.makeMoveVec({ objects: [subPath1] }), // coins
        subPath1Value,                          // amount
        txb.pure(0),                            // amount_limit
        txb.pure(0),                            // order_id
        txb.pure(6),                            // USDC decimal
    ],
    typeArguments: [USDT_TYPE, USDC_TYPE]
});

// Sub-path 2: USDC → USDT via SuiSwap (80% of 60%)
const [suiswapOut, suiswapAmount] = txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::suiswap_swap_b2a_with_return`,
    arguments: [
        txb.object(SUISWAP_POOL),               // pool
        txb.makeMoveVec({ objects: [subPath2] }), // coins
        subPath2Value,                          // amount
        txb.pure(0),                            // amount_limit
        txb.pure(0),                            // order_id
        txb.pure(6),                            // USDC decimal
    ],
    typeArguments: [USDT_TYPE, USDC_TYPE]
});

// Merge all USDT outputs
txb.mergeCoins(cetusOut, [kriyaOut, suiswapOut]);

// Finalize merged output
txb.moveCall({
    target: `${ROUTER_PACKAGE}::router::finalize`,
    arguments: [
        cetusOut,                               // merged USDT
        txb.pure(1),                            // min_amount
        txb.pure(0),                            // commission_rate
        txb.pure(walletAddress),                // referral_address
        txb.pure(walletAddress),                // receiver_address
        txb.pure(0),                            // order_id
        txb.pure(USDT_DECIMAL),                 // decimal
    ],
    typeArguments: [USDT_TYPE]
});

txb.setSender(walletAddress);

// Build and execute transaction
const builtTx = await txb.build({ client: provider });
const result = await provider.dryRunTransactionBlock({
    transactionBlock: builtTx
});
```

### Result
✅ Sequential split routing functionality (exact pattern from test)  
✅ Multi-layer protocol execution  
✅ Complete DEX router implementation

### 🏆 Mastery Complete!
You've mastered the 3 essential DEX-Router-Sui patterns:
- **Basic Swap Integration**: Single protocol CLMM swaps
- **Commission System**: Fee collection and distribution strategies  
- **Advanced Routing**: Complex multi-protocol sequential routing

---

## 🎯 Quick Reference Guide

### Common Issues & Solutions

**❌ Issue**: Swap instruction fails with "insufficient funds"
**✅ Solution**: Check gas budget allocation and ensure sufficient SUI for transaction fees

**❌ Issue**: Commission not being collected
**✅ Solution**: Check commission rate setup and verify `split_with_percentage_for_commission` usage

**❌ Issue**: Multi-protocol swap fails
**✅ Solution**: Ensure all pool addresses are current and token types match exactly

### Essential Constants Quick Reference

```typescript
// Core Token Types
const SUI_TYPE = "0x2::sui::SUI";
const USDC_TYPE = "0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN";
const USDT_TYPE = "0xc060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN";

// Core Contract Addresses (Note: These addresses may be updated in future versions)
const ROUTER_PACKAGE = "0xafff5502633f670a64328813b66fa08bc7a642ac9c81ed6c4b7ec5448e3b23ad";
const EXTENDED_PACKAGE = "0xab71c2c2c37f973e28b2d28847046615bf47acc85ffc3ba2eb3d9a6442b18422";
const SUI_CLOCK_OBJECT_ID = "0x6";

// Decimal Precision
const SUI_DECIMAL = 9;
const USDC_DECIMAL = 6;
const USDT_DECIMAL = 6;
const LAMPORTS_PER_SUI = 1_000_000_000;

// Commission Calculations
const BASIS_POINTS = 10000; // 1% = 100 basis points
const MAX_COMMISSION = 300; // 3% maximum commission rate

// Gas Budget Recommendations
const BASIC_SWAP_GAS = 4051120;
const COMPLEX_ROUTING_GAS = 10000000;
```

### Test Script Execution
```bash
# Run specific test patterns
npx ts-node script/test/swap.ts                    # Basic swap
npx ts-node script/test/commission.ts              # Commission system
npx ts-node script/test/multihop-sequential-split.ts # Advanced routing

# Protocol-specific tests
npx ts-node script/test/dexes/cetus.ts            # Cetus CLMM
npx ts-node script/test/dexes/turbos.ts           # Turbos integration
npx ts-node script/test/dexes/flowxv3.ts          # FlowX V3 CLMM
```

### Note
**Contract Address Updates**: The contract addresses shown in this guide may be updated in future versions. 