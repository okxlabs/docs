# DEX-Router-Aptos-V1 Implementation Guides

## Getting Started

These guides will help you implement **production-ready** token swapping functionality using the DEX-Router-Aptos-V1 system. Each guide is designed to be completed within 10 minutes and provides complete, working examples based on real implementation patterns.

**💡 Production-Ready Examples**: All code examples in these guides are derived from actual working TypeScript tests and are available in our source repository for easy reference and implementation.

**📋 Three Essential Guides**: We provide comprehensive guides covering all major swap types:
- **Guide 1**: Single-Hop Token Swap Integration 
- **Guide 2**: Multi-Hop Cross-Protocol Routing
- **Guide 3**: Fungible Asset (FA) Support

**🔧 What's Different**: Unlike simplified tutorial examples, these guides show you the complete implementation including proper parameter encoding, asset format handling, and production-grade error handling using TypeScript.

## Prerequisites

- Basic understanding of Move and Aptos smart contracts
- Access to a deployed DEX-Router contract
- Node.js and npm installed
- Aptos CLI development environment

## Guide 1: Single-Hop Token Swap Integration

### Introduction
This guide demonstrates single-hop token swaps using the DEX-Router with TypeScript integration based on patterns from `scripts/tests/singleHop.ts`.

### Implementation

```typescript
// From testPontemV2_APT_to_UPTOS()
import { executeSwap, createFAConfig } from "../testHelper";
import { TOKENS, DEX, FA_ADDRESSES } from "../config";
import { getUser } from "../util";

export async function testPontemV2_APT_to_UPTOS() {
    console.log("\n=== Pontem V2: APT -> UPTOS ===");
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.APT,
            TOKENS.UPTOS,
            {
                amountIn: 1000000,      // 0.01 APT
                minAmountOut: 12368548300,
                dexTypes: [DEX.PONTEM_V2],
                poolTypes: [0]
            }
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}
```

### Result
✅ Basic single-hop swap integration (exact pattern from test)  
✅ APT → UPTOS conversion capability via Pontem V2

---

## Guide 2: Multi-Hop Cross-Protocol Routing

### Introduction
This guide demonstrates multi-hop routing across different DEX protocols using patterns from `scripts/tests/multiHop.ts`.

### Implementation

```typescript
// From testMultiHop_UPTOS_APT_CELL()
export async function testMultiHop_UPTOS_APT_CELL() {
    console.log("\n=== Multi-hop: UPTOS -> APT -> CELL ===");
    console.log("Route: UPTOS --(PontemV2)--> APT --(Cellana)--> CELL");
    
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.UPTOS,
            TOKENS.APT,  // Output token type (FA also needs placeholder)
            {
                amountIn: 100000000000,   // 1000 UPTOS
                minAmountOut: 10000000,
                dexTypes: [DEX.PONTEM_V2, DEX.CELLANA],
                poolTypes: [1, 1],
                isXToY: [true, true],
                faConfig: createFAConfig({
                    outputIsFA: true,
                    outputFAAddress: FA_ADDRESSES.CELL
                })
            },
            TOKENS.APT  // Intermediate token
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}
```

### Result
✅ Multi-hop cross-protocol routing (exact pattern from test)  
✅ UPTOS → APT → CELL conversion across protocols

---

## Guide 3: Fungible Asset (FA) Support

### Introduction
This guide demonstrates how to handle Fungible Asset (FA) format tokens using patterns from the test suite.

### Implementation

```typescript
// From testCellana_APT_to_CELL()
export async function testCellana_APT_to_CELL() {
    console.log("\n=== Cellana: APT -> CELL (FA) ===");
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.APT,
            TOKENS.UPTOS,  // Note: FA tokens still need placeholder type
            {
                amountIn: 1000000,      // 0.01 APT
                minAmountOut: 100000000,
                dexTypes: [DEX.CELLANA],
                poolTypes: [1],
                faConfig: createFAConfig({
                    outputIsFA: true,
                    outputFAAddress: FA_ADDRESSES.CELL
                })
            }
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}
```

### Result
✅ Fungible Asset support integration (exact pattern from test)  
✅ APT → CELL (FA) conversion capability

### 🏆 Mastery Complete!
You've mastered the 3 essential DEX-Router-Aptos patterns:
- **Single-Hop Integration**: Basic token swaps through single protocol
- **Multi-Hop Routing**: Cross-protocol routing with multiple hops  
- **Fungible Asset Support**: Modern FA token format handling

---

## 🎯 Quick Reference Guide

### Common Issues & Solutions

**❌ Issue**: Swap fails with "E_OUTPUT_LESS_THAN_MINIMUM"
**✅ Solution**: Increase slippage tolerance or check market conditions

**❌ Issue**: "E_UNKNOWN_DEX" error occurs
**✅ Solution**: Use supported DEX constants (3, 7, 8, 9, 10) and verify protocol support

**❌ Issue**: FA swap fails with "E_FA_NOT_SUPPORTED"
**✅ Solution**: Use FA-supporting protocols (Cellana, Hyperion) for FA assets

### Essential Constants Quick Reference

```typescript
// Core Token Types
const TOKENS = {
    APT: "0x1::aptos_coin::AptosCoin",
    USDC: "0x5e156f1207d0ebfa19a9eeff00d62a282278fb8719f4fab3a586a0a2c0fffbea::coin::T",
    USDT: "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT",
    UPTOS: "0x4fbed3f8a3fd8a11081c8b6392152a8b0cb14d70d0414586f0c9b858fcd2d6a7::UPTOS::UPTOS"
};

// Core DEX Constants
const DEX = {
    PONTEM: 3,
    PONTEM_V2: 8,
    PANCAKE: 7,
    CELLANA: 9,
    HYPERION: 10
};

// FA Addresses
const FA_ADDRESSES = {
    CELL: "0x2ebb2ccac5e027a87fa0e2e5f656a3a4238d6a48d93ec9b610d570fc0aa0df12",
    USDT_FA: "0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b"
};

// Module Configuration
const MODULE_ADDRESS = "0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1";
const MODULE_NAME = "aggregator";
```

### Test Script Execution
```bash
# Run specific test patterns
npx ts-node scripts/tests/singleHop.ts                # Single-hop swaps
npx ts-node scripts/tests/multiHop.ts                 # Multi-hop routing

# Run individual test functions
npx ts-node -e "
import { testPontemV2_APT_to_UPTOS } from './scripts/tests/singleHop';
testPontemV2_APT_to_UPTOS().catch(console.error);
"
```

### Note
**Contract Address Updates**: The contract addresses shown in this guide may be updated in future versions. Always verify current addresses before mainnet deployment.