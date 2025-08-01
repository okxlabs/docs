# DEX Router - Integration Guides

## Learning Path Overview

**Total Completion Time: 20 minutes**

This guide provides focused integration patterns for the DEX Router on Sui blockchain. Each guide builds core competency in 10 minutes, derived from proven test suite patterns.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Learning Path Map                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐                                            │
│  │ Guide 1     │→ │ Guide 2     │                                            │
│  │             │  │             │                                            │
│  │ Core CLMM   │  │ Commission  │                                            │
│  │ Integration │  │ System      │                                            │
│  │ 10 min      │  │ 10 min      │                                            │
│  └─────────────┘  └─────────────┘                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Prerequisites
- **Sui CLI**: Installed and configured
- **TypeScript/JavaScript**: Basic understanding of TypeScript
- **Wallet Setup**: Sui wallet with mainnet SUI
- **Dependencies**: `@mysten/sui.js`, `dotenv`, and TypeScript development tools installed

### Environment Setup
```typescript
// package.json dependencies
{
  "dependencies": {
    "@mysten/sui.js": "^0.54.1",
    "@types/node": "^20.12.13",
    "dotenv": "^16.4.7",
    "node-fetch": "^3.3.2",
    "ts-node": "^10.9.2",
    "typescript": "^5.4.5"
  }
}

// .env file
PRIVATE_KEY_STR=your_base64_private_key_here

// Run TypeScript files directly with:
// npx ts-node your-script.ts

// Basic wallet initialization
import dotenv from "dotenv";
dotenv.config();

const PRIVATE_KEY_STR = process.env.PRIVATE_KEY_STR!;
const PRIVATE_KEY = Buffer.from(PRIVATE_KEY_STR, "base64").subarray(1);

const connection = new Connection({
  "fullnode": "https://sui-rpc.publicnode.com" // mainnet
});

const provider = new JsonRpcProvider(connection);
const wallet = new RawSigner(
  Ed25519Keypair.fromSecretKey(PRIVATE_KEY),
  provider
);
```

### Test Suite Reference
All examples derived from actual test suite in router contracts. Examples modified for clarity while maintaining functional accuracy.

---

## Guide 1: Core CLMM Integration

**What You'll Build**: Basic Cetus CLMM swap integration in 10 minutes.

### Essential Setup
```typescript
import {
  Connection,
  Ed25519Keypair,
  JsonRpcProvider,
  RawSigner,
  SUI_CLOCK_OBJECT_ID,
  TransactionBlock
} from "@mysten/sui.js";

// DEX Router Contract Addresses (Mainnet)
const DEX_ROUTER = "0x3b79de9a1f64fed053481f0682b272cdc4ca7ae849699d594cb362b05afe4a2f";
const DEX_EXTENDED = "0xe810da8bfdec2629a5b78fdd279db943fc1ced2281de3e63f8f7f0588d515ae2";

// Token Contract IDs (Mainnet)
const USDC_ID = "0x5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf";
const SUI_ID = "0x0000000000000000000000000000000000000000000000000000000000000002";

// Token Types
const USDC_TYPE = `${USDC_ID}::coin::COIN`;
const SUI_TYPE = `${SUI_ID}::sui::SUI`;
const MIN_OUTPUT = 0; // No minimum output required

// Pool Configuration (Example - replace with actual pool addresses)
const GLOBAL_CONFIG = "0xdaa46292632c3c4d8f31f23ea0f9b36a28ff3677e9684980e4438403a67a3d8f";
const POOL = "0xcf994611fd4c48e277ce3ffd4d4364c914af2c3cbb05f7bf6facd371de688630";
```

### Core Pattern
```typescript
async function basicCetusSwap(
  wallet: RawSigner,
  amount: number
) {
  const txb = new TransactionBlock();
  txb.setGasBudget(4051120);
  
  // Split SUI for swap
  const amountCoin = txb.splitCoins(txb.gas, [txb.pure(amount.toString())]);
  
  // Execute swap
  const [usdc_out, amount_out] = txb.moveCall({
    target: `${DEX_ROUTER}::router::cetus_swap_b2a_with_return`,
    arguments: [
      txb.object(GLOBAL_CONFIG),
      txb.object(POOL),
      txb.makeMoveVec({ objects: [amountCoin] }),
      txb.pure(true),                                    // by_amount_in
      txb.pure(amount),                                  // amount
      txb.pure(0),                                       // amount_limit
      txb.pure(BigInt("79226673515401279992447579055")), // sqrt_price_limit
      txb.object(SUI_CLOCK_OBJECT_ID),                   // clock
      txb.pure(0),                                       // order_id
      txb.pure(6),                                       // USDC decimals
    ],
    typeArguments: [USDC_TYPE, SUI_TYPE]
  });
  
  // Finalize (no commission)
  txb.moveCall({
    target: `${DEX_ROUTER}::router::finalize`,
    arguments: [
      usdc_out,
      txb.pure(0),
      txb.pure(0), // No commission
      txb.pure("0x0"), // No referral
      txb.pure("0x0"), // Use sender
      txb.pure(0), // Order ID
      txb.pure(6) // USDC decimals
    ],
    typeArguments: [USDC_TYPE]
  });
  
  // Execute transaction
  const result = await wallet.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEvents: true, showEffects: true }
  });
  
  return result;
}
```

### Key Integration Points
- **Return Format**: `[coin_out, amount_out]` destructuring for chaining
- **Finalize Required**: Always call `finalize` move call for proper cleanup
- **Gas Budget**: Set appropriate gas budget
- **Transaction Options**: Include `showEvents: true` to capture commission/order records

**Next Guide** → Commission System

---

## Guide 2: Commission System

**What You'll Build**: Commission-enabled swap with referral rewards in 10 minutes.

### Commission Setup
```typescript
const COMMISSION_RATE = 100;          // 1% (basis points)
const MAX_COMMISSION = 300;           // 3% maximum
const REFERRAL_ADDRESS = "0x123..."; // Partner address
```

### Commission Pattern
```typescript
async function swapWithCommission(
  wallet: RawSigner,
  amount: number,
  referralAddress: string
) {
  const txb = new TransactionBlock();
  txb.setGasBudget(4051120);
  
  // Split SUI for swap
  const amountCoin = txb.splitCoins(txb.gas, [txb.pure(amount.toString())]);
  
  // Execute swap
  const [usdc_out, amount_out] = txb.moveCall({
    target: `${DEX_ROUTER}::router::cetus_swap_b2a_with_return`,
    arguments: [
      txb.object(GLOBAL_CONFIG),
      txb.object(POOL),
      txb.makeMoveVec({ objects: [amountCoin] }),
      txb.pure(true),                                    // by_amount_in
      txb.pure(amount),                                  // amount
      txb.pure(0),                                       // amount_limit
      txb.pure(BigInt("79226673515401279992447579055")), // sqrt_price_limit
      txb.object(SUI_CLOCK_OBJECT_ID),                   // clock
      txb.pure(0),                                       // order_id
      txb.pure(6),                                       // USDC decimals
    ],
    typeArguments: [USDC_TYPE, SUI_TYPE]
  });
  
  // Commission processing in finalize
  txb.moveCall({
    target: `${DEX_ROUTER}::router::finalize`,
    arguments: [
      usdc_out,
      txb.pure(0),
      txb.pure(COMMISSION_RATE),    // 1% commission
      txb.pure(referralAddress),    // Receives commission
      txb.pure("0x0"),             // Sender receives remainder
      txb.pure(0),        // Order ID
      txb.pure(6)                  // USDC decimals
    ],
    typeArguments: [USDC_TYPE]
  });
  
  // Execute transaction
  const result = await wallet.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    options: { showEvents: true, showEffects: true }
  });
  
  return result;
}
```

### Commission Validation
```typescript
// Automatic validation in finalize function:
// - commission_rate <= MAX_COMMISSION (300 basis points = 3%)
// - commission_rate == 0 || referral_address != "0x0"
// - Validation happens on-chain during execution
```


**Next Guide** → Complete!

---




## Completion Summary

**✅ What You've Learned**:
1. **Core Integration**: Basic CLMM swap patterns
2. **Commission System**: Referral rewards and fee distribution

**🚀 Next Steps**:
- Explore more protocols
- Build custom routing logic
- Deploy to production with monitoring
- Implement advanced features like MEV protection

**📚 Resources**:
- **Technical Reference**: Complete API documentation
- **Test Suite**: Router contract test cases for validation
- **Community**: Sui developer ecosystem support

---

*For detailed API specifications, see technical-reference.md* 