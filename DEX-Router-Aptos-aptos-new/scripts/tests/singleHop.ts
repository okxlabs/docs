/**
 * Single-hop swap tests for OKX DEX Aggregator
 * Tests various DEX adapters with single-hop token exchanges
 */

import { executeSwap, createFAConfig } from "../testHelper";
import { TOKENS, DEX, FA_ADDRESSES } from "../config";
import { getUser } from "../util";

/**
 * Tests Pontem V2 DEX: APT -> UPTOS swap
 * Demonstrates basic coin-to-coin single-hop exchange
 */
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

/**
 * Tests Cellana DEX: APT -> USDT swap
 * Demonstrates coin-to-coin swap through Cellana adapter
 */
export async function testCellana_APT_to_USDT() {
    console.log("\n=== Cellana: APT -> USDT ===");
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.APT,
            TOKENS.USDT,
            {
                amountIn: 1000000,      // 0.01 APT
                minAmountOut: 8000,
                dexTypes: [DEX.CELLANA],
                poolTypes: [1]
            }
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}

/**
 * Tests Cellana DEX: APT -> CELL (Fungible Asset) swap
 * Demonstrates coin-to-FA swap using Cellana's FA support
 */
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

/**
 * Tests Hyperion DEX: APT -> FA swap
 * Demonstrates coin-to-FA swap using Hyperion-specific FA token
 */
export async function testHyperion_APT_to_FA() {
    console.log("\n=== Hyperion: APT -> FA ===");
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.APT,
            TOKENS.UPTOS,  // Placeholder type, actual output is FA
            {
                amountIn: 1000000,        // 0.01 APT
                minAmountOut: 1,        // Minimum output: 1 unit
                dexTypes: [DEX.HYPERION],
                poolTypes: [1],
                faConfig: createFAConfig({
                    outputIsFA: true,
                    outputFAAddress: FA_ADDRESSES.USDT_FA
                })
            }
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
        console.log("Reference: https://explorer.aptoslabs.com/txn/2746495386/events?network=mainnet");
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}

/**
 * Tests FA -> Coin swap (demonstrates inputIsFA usage)
 * Shows how to swap from Fungible Asset to traditional Coin
 */
export async function testHyperion_FA_to_Coin() {
    console.log("\n=== FA -> Coin: FA -> APT ===");
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.UPTOS,  // Placeholder type, actual input is FA
            TOKENS.APT,
            {
                amountIn: 10000,   // 0.01 USDT
                minAmountOut: 1,   
                dexTypes: [DEX.HYPERION],
                poolTypes: [1],
                faConfig: createFAConfig({
                    inputIsFA: true,
                    inputFAAddress: FA_ADDRESSES.USDT_FA
                })
            }
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}

/**
 * Runs all single-hop swap tests sequentially
 * Executes comprehensive test suite for all supported single-hop scenarios
 */
export async function runAllSingleHopTests() {
    // await testPontemV2_APT_to_UPTOS();
    // await testCellana_APT_to_USDT();
    // await testCellana_APT_to_CELL();
    // await testHyperion_APT_to_FA();
    await testHyperion_FA_to_Coin();
}

// Execute all tests if this file is run directly
if (require.main === module) {
    runAllSingleHopTests().catch(console.error);
}
