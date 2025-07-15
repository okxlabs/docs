# DEX-Router-Solana Implementation Guides

## Getting Started

These guides provide **step-by-step** implementation examples for the DEX-Router-Solana system. Each guide focuses on a single concept and can be completed in **under 10 minutes**.

**💡 Real Implementation Examples**: All code examples are derived from working test implementations under `tests/instructions/swap_v3/`.

## 🗺️ 10-Minute Learning Path

```
🎯 Essential Guides | Total = 30 Minutes

Guide 1 ────▶ Guide 2 ────▶ Guide 3
PumpFun      Commission     swapTobV3
```

**📋 Essential swap_v3 Guides** *(10 min each)*:
- **Guide 1**: PumpFun Integration *(Meme token trading)*
- **Guide 2**: Commission Fee *(Fee collection)*
- **Guide 3**: swapTobV3 Trim *(Advanced fee layers)*

## Prerequisites

- Node.js 18+ and npm/yarn
- Basic understanding of Solana and TypeScript
- Access to Solana RPC endpoint
- **All patterns follow exact test cases from `tests/instructions/swap_v3/`**

---

## Guide 1: PumpFun Integration

### What You'll Build
Use `swapV3` for PumpFun integration with the exact pattern from test in **10 minutes**.

### Quick Setup
```typescript
import * as anchor from '@coral-xyz/anchor';
import { PublicKey, ComputeBudgetProgram } from '@solana/web3.js';
import { TOKEN_PROGRAM_ID } from '@solana/spl-token';
import { BN } from 'bn.js';

// Constants (from swap_v3 test)
const MINT_WSOL = new PublicKey("So11111111111111111111111111111111111111112");
const MINT_PUMPFUN_TOKEN = new PublicKey("PumpFunTokenMint...");
const PUMPFUN_PROGRAM_ID = new PublicKey("6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P");
const SA_PDA = new PublicKey("SwapAuthorityPDA...");
```

### PumpFun Setup
```typescript
// PumpFun constants
const PUMPFUN_PROGRAM_ID = new PublicKey("6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P");
const memeTokenMint = new PublicKey("TokenMintAddress..."); // Target token

// PumpFun accounts
const pumpfunAccounts = [
    { pubkey: PUMPFUN_PROGRAM_ID, isSigner: false, isWritable: false },
    { pubkey: payer, isSigner: true, isWritable: true },
    { pubkey: sourceTokenAccount, isSigner: false, isWritable: true },
    { pubkey: destinationTokenAccount, isSigner: false, isWritable: true },
    { pubkey: new PublicKey('4wTV1YmiEkRvAtNtsSGPtUrqRYQMe5SKy2uB4Jjaxnjf'), isSigner: false, isWritable: false }, // global
    { pubkey: new PublicKey('62qc2CNXwrYqQScmEdiZFFAnJR262PxWEuNQtxfafNgV'), isSigner: false, isWritable: true }, // fee_recipient
    { pubkey: memeTokenMint, isSigner: false, isWritable: false }, // mint
    { pubkey: new PublicKey('EAjRpWwzRgzTSC53u3AMC29883eBmtCnYaJheUPY3SSg'), isSigner: false, isWritable: true }, // bonding_curve
    { pubkey: new PublicKey('C8cAYFHfjZyvzKqe9E8LyhYUL8W3GrW9x2K1WF8gZZ6m'), isSigner: false, isWritable: true }, // associated_bonding_curve
    { pubkey: new PublicKey("11111111111111111111111111111111"), isSigner: false, isWritable: false }, // system_program
    { pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false },
    { pubkey: new PublicKey('EijcArzYy2zWsRzPAa6DHX7q3FibPd5cFUN3bjGDd9xB'), isSigner: false, isWritable: true }, // creator_vault
    { pubkey: new PublicKey('Ce6TQqeHC9p8KetsN6JsjHK7UTZk7nasjjnr7XxXp9F1'), isSigner: false, isWritable: false } // event_authority
];
```

### Implementation
```typescript
// PumpFun route configuration
const route = { dexes: [{ pumpfunBuy: {} }], weights: Buffer.from([100]) };

const data = {
    amountIn: new BN(1_000_000), // 0.001 SOL
    expectAmountOut: new BN(100),
    minReturn: new BN(100),
    amounts: [new BN(1_000_000)],
    routes: [[route]]
};

// Commission setup (following swap_v3 pattern)
const commissionAccount = None;
const commissionRate = 0; // Commission rate, 0 means no commission fee
const commissionDirection = false; // Commission direction: true-fromToken, false-toToken
const commissionInfo = Number((BigInt(commissionDirection ? 1 : 0) << BigInt(31)) | BigInt(commissionRate & 0x7fffffff));
const platformFeeRate = 0; // Platform fee rate, 0 means no Platform fee
const orderId = new BN(1);

// Execute meme token purchase using swapV3 (exact pattern from test)
const instruction = await dexRouter.methods
    .swapV3(data, commissionInfo, platformFeeRate, orderId)
    .accounts({
        payer: payer,
        sourceTokenAccount: sourceTokenAccount,
        destinationTokenAccount: destinationTokenAccount,
        sourceMint: MINT_WSOL,
        destinationMint: memeTokenMint,
        commissionAccount: commissionAccount,
        platformFeeAccount: commissionAccount,
        saAuthority: SA_PDA,
        sourceTokenSa: null,
        destinationTokenSa: null,
        sourceTokenProgram: TOKEN_PROGRAM_ID,
        destinationTokenProgram: TOKEN_PROGRAM_ID
    })
    .remainingAccounts(pumpfunAccounts)
    .instruction();
```

### Result
✅ swapV3 PumpFun integration (exact pattern from test)  
✅ Meme token trading capability

### Next: [Guide 2 - Commission Fee](#guide-2-commission-fee)

---

## Guide 2: Commission Fee

### What You'll Build
Use `swapV3` to collect commission fees with the exact pattern from Phoenix test in **10 minutes**.

### Fee Configuration
```typescript
// Commission setup (following swap_v3 pattern)
const commissionAccount = new PublicKey('36Vtyos4qTw2gt3473U6Jqc8TGuYdVriexsEFix3WPhN');
const commissionRate = 100000000; // Commission rate
const commissionDirection = true; // Commission direction: true-fromToken, false-toToken
const commissionInfo = Number((BigInt(commissionDirection ? 1 : 0) << BigInt(31)) | BigInt(commissionRate & 0x7fffffff));
const platformFeeRate = 10000; // Platform fee rate
const orderId = new BN(1);
```

### Implementation
```typescript
// Phoenix route configuration
const route = { dexes: [{ phoenix: {} }], weights: Buffer.from([100]) };

const data = {
    amountIn: new BN(1_000_000), // 0.001 SOL
    expectAmountOut: new BN(100),
    minReturn: new BN(100),
    amounts: [new BN(1_000_000)],
    routes: [[route]]
};

// Phoenix DEX accounts (from swap_v3 test case)
const phoenixAccounts = [
    { pubkey: PHOENIX_PROGRAM_ID, isSigner: false, isWritable: false }, // dex_program_id
    { pubkey: SA_PDA, isSigner: false, isWritable: true }, // swap_authority_pubkey
    { pubkey: SA_WSOL, isSigner: false, isWritable: true }, // swap_source_token
    { pubkey: SA_USDC, isSigner: false, isWritable: true }, // swap_destination_token
    { pubkey: new PublicKey('7aDTsspkQNGKmrexAN7FLx9oxU3iPczSSvHNggyuqYkR'), isSigner: false, isWritable: true }, // log_authority
    { pubkey: new PublicKey('4DoNfFBfF7UokCC2FQzriy7yHK6DY6NVdYpuekQ5pRgg'), isSigner: false, isWritable: true }, // market
    { pubkey: new PublicKey('8g4Z9d6PqGkgH31tMW6FwxGhwYJrXpxZHQrkikpLJKrG'), isSigner: false, isWritable: true }, // base_vault
    { pubkey: new PublicKey('3HSYXeGc3LjEPCuzoNDjQN37F1ebsSiR4CqXVqQCdekZ'), isSigner: false, isWritable: true }, // quote_vault
    { pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false } // token_program
];

// Use swapV3 method (exact pattern from test)
const instruction = await dexRouter.methods
    .swapV3(data, commissionInfo, platformFeeRate, orderId)
    .accounts({
        payer: payer,
        sourceTokenAccount: sourceTokenAccount,
        destinationTokenAccount: destinationTokenAccount,
        sourceMint: MINT_WSOL,
        destinationMint: MINT_USDC,
        commissionAccount: commissionAccount,
        platformFeeAccount: commissionAccount,
        saAuthority: SA_PDA,
        sourceTokenSa: SA_WSOL,
        destinationTokenSa: SA_USDC,
        sourceTokenProgram: TOKEN_PROGRAM_ID,
        destinationTokenProgram: TOKEN_PROGRAM_ID
    })
    .remainingAccounts(phoenixAccounts)
    .instruction();
```

### Result
✅ swapV3 with commission fees (exact pattern from test)  
✅ Phoenix DEX integration with fee collection

### Next: [Guide 3 - swapTobV3 Trim](#guide-3-swaptobv3-trim)

---

## Guide 3: swapTobV3 Trim

### What You'll Build
Use `swapTobV3` for trim swaps with the exact pattern from PumpFun trim test in **10 minutes**.

### Trim Configuration
```typescript
// Enhanced fee structure: commission + platform + trim (following swap_v3 pattern)
const commissionAccount = new PublicKey('36Vtyos4qTw2gt3473U6Jqc8TGuYdVriexsEFix3WPhN');
const commissionRate = 100000000; // Commission rate
const commissionDirection = false; // Commission direction: true-fromToken, false-toToken
const commissionInfo = Number((BigInt(commissionDirection ? 1 : 0) << BigInt(31)) | BigInt(commissionRate & 0x7fffffff));
const platformFeeRate = 10000; // Platform fee rate
const trimRate = 100; // Trim rate
const orderId = new BN(1);

// Token-specific commission account for destination token
const commissionTokenAccount = await getAssociatedTokenAddress(destinationMint, commissionAccount);
const saTrimAccount = await getAssociatedTokenAddress(destinationMint, SA_PDA);
```

### Implementation
```typescript
// PumpFun route configuration
const route = { dexes: [{ pumpfunBuy: {} }], weights: Buffer.from([100]) };

const data = {
    amountIn: new BN(1_000_000), // 0.001 SOL
    expectAmountOut: new BN(100),
    minReturn: new BN(100),
    amounts: [new BN(1_000_000)],
    routes: [[route]]
};

// PumpFun accounts (from swap_v3 test case)
const pumpfunAccounts = [
    { pubkey: PUMPFUN_PROGRAM_ID, isSigner: false, isWritable: false }, // dex_program_id
    { pubkey: payer, isSigner: true, isWritable: true }, // user address
    { pubkey: sourceTokenAccount, isSigner: false, isWritable: true }, // swap_source_token
    { pubkey: saTrimAccount, isSigner: false, isWritable: true }, // swap_destination_token
    { pubkey: new PublicKey('4wTV1YmiEkRvAtNtsSGPtUrqRYQMe5SKy2uB4Jjaxnjf'), isSigner: false, isWritable: false }, // global
    { pubkey: new PublicKey('62qc2CNXwrYqQScmEdiZFFAnJR262PxWEuNQtxfafNgV'), isSigner: false, isWritable: true }, // pumpfun fee recipient
    { pubkey: destinationMint, isSigner: false, isWritable: false }, // mint address
    { pubkey: new PublicKey('EAjRpWwzRgzTSC53u3AMC29883eBmtCnYaJheUPY3SSg'), isSigner: false, isWritable: true }, // bonding curve
    { pubkey: new PublicKey('C8cAYFHfjZyvzKqe9E8LyhYUL8W3GrW9x2K1WF8gZZ6m'), isSigner: false, isWritable: true }, // associated bonding curve
    { pubkey: SYSTEM_PROGRAM_ID, isSigner: false, isWritable: false }, // system program
    { pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false }, // token program
    { pubkey: new PublicKey('EijcArzYy2zWsRzPAa6DHX7q3FibPd5cFUN3bjGDd9xB'), isSigner: false, isWritable: true }, // creator vault
    { pubkey: new PublicKey('Ce6TQqeHC9p8KetsN6JsjHK7UTZk7nasjjnr7XxXp9F1'), isSigner: false, isWritable: false } // event authority
];

// Add trim account
const remainingAccounts = [...pumpfunAccounts, {
    pubkey: commissionTokenAccount,
    isSigner: false,
    isWritable: true
}];

// Use swapTobV3 method for trim functionality (exact pattern from test)
const instruction = await dexRouter.methods
    .swapTobV3(data, commissionInfo, trimRate, platformFeeRate, orderId)
    .accounts({
        payer: payer,
        sourceTokenAccount: sourceTokenAccount,
        destinationTokenAccount: destinationTokenAccount,
        sourceMint: sourceMint,
        destinationMint: destinationMint,
        commissionAccount: commissionTokenAccount,
        platformFeeAccount: commissionTokenAccount,
        saAuthority: SA_PDA,
        sourceTokenSa: null,
        destinationTokenSa: saTrimAccount,
        sourceTokenProgram: TOKEN_PROGRAM_ID,
        destinationTokenProgram: TOKEN_PROGRAM_ID
    })
    .remainingAccounts(remainingAccounts)
    .instruction();
```

### Result
✅ swapTobV3 trim functionality (exact pattern from test)  
✅ Multi-layer fee collection  
✅ Complete DEX router implementation

### 🏆 Mastery Complete!
You've mastered the 3 essential DEX-Router-Solana patterns:
- **PumpFun Integration**: Meme token trading
- **Commission Fees**: Monetization strategies  
- **swapTobV3 Trim**: Advanced fee structures

---

## 🎯 Quick Reference Guide

### Common Issues & Solutions

**❌ Issue**: Swap instruction fails with "insufficient funds"
**✅ Solution**: Check compute budget allocation and ensure sufficient SOL for fees

**❌ Issue**: Commission not being collected
**✅ Solution**: Check commission account setup and verify bit-packing configuration

**❌ Issue**: PumpFun swap fails
**✅ Solution**: Ensure bonding curve accounts are current and token mint is valid

### Essential Constants Quick Reference

```typescript
// Core Token Mints
const MINT_WSOL = "So11111111111111111111111111111111111111112";
const MINT_USDC = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v";
const MINT_USDT = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB";

// Core Programs
const TOKEN_PROGRAM_ID = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
const SYSTEM_PROGRAM_ID = "11111111111111111111111111111111";
const PUMPFUN_PROGRAM_ID = "6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P";

// Fee Calculations
const BASIS_POINTS = 10000; // 1% = 100 basis points
const LAMPORTS_PER_SOL = 1_000_000_000;

// Commission Info Bit-Packing (swapV3/swapTobV3)
const commissionInfo = Number(
    (BigInt(commissionDirection ? 1 : 0) << BigInt(31)) | 
    BigInt(commissionRate & 0x7fffffff)
);
```


